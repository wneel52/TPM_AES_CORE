"""
Proof of concept for a FSM locked AES core.
We will have different classes representing different modules of the core, and we will use a simple FSM to control the flow of the encryption process.
The "data fabric" is represented by IO operations between classes
"""
from dataclasses import dataclass, field
from enum import Enum, auto
from collections import deque
from aes import AES
import sys
import io

class CoreState(Enum):
    IDLE = 0
    BUSY = 1
    ERROR = 2


class DevState(Enum):
    LOCKED = auto()
    UNLOCKED_SHIFT = auto()
    UNLOCKED = auto()
    TRAPPED = auto()


class CMD(Enum):
    STATUS = auto()
    UNLOCK_WORD = auto()
    LOAD_KEY_WORD = auto()
    COMMIT_KEY = auto()
    ENCRYPT_BLOCK = auto()
    READ_RESULT = auto()
    ZEROIZE = auto()


@dataclass
class Response:
    ok: bool
    code: str
    data: dict = field(default_factory=dict)


class keyVault:
    def __init__(self):
        self.key_words = [0, 0, 0, 0]
        self.key_committed = False

    def load_word(self, idx: int, word: int):
        if self.key_committed:
            print("Key already committed, cannot load new word")
            return
        if idx < 0 or idx > 3:
            print("Invalid index, must be between 0 and 3")
            return
        self.key_words[idx] = word & 0xFFFFFFFF

    def commit(self) -> bool:
        if len(self.key_words) not in (4, 8):  # 128-bit or 256-bit
            print(f"Invalid key length ({len(self.key_words)} words), must be 4 or 8 words")
            return False
        self.key_committed = True
        return True

    def zeroize(self):
        self.key_words = [0, 0, 0, 0]
        self.key_committed = False

    def get_key_words(self):
        """Return key as tuple of 32-bit words for aes.py"""
        return tuple(self.key_words)


class AESCore:
    def __init__(self):
        self.state = CoreState.IDLE
        self.result = None
        self.key_words = None
        self.aes = AES(verbose=False, dump_vars=False)  # Disable verbose output

    def init_key(self, key_words: tuple):
        """key_words: tuple of 4 (128-bit) or 8 (256-bit) 32-bit integers"""
        self.key_words = key_words

    def encrypt(self, block_bytes: bytes):
        """block_bytes: 16 bytes to encrypt"""
        if self.key_words is None:
            print("No key loaded, cannot encrypt")
            self.state = CoreState.ERROR
            return
        if self.state == CoreState.BUSY:
            print("Core is busy, cannot start encryption")
            return
        
        # Convert 16 bytes to tuple of 4 32-bit words (big-endian)
        block_words = tuple(
            int.from_bytes(block_bytes[i:i+4], byteorder='big')
            for i in range(0, 16, 4)
        )
        
        self.state = CoreState.BUSY
        # Call aes.py encipher_block (suppress verbose output)
        old_stdout = sys.stdout
        sys.stdout = io.StringIO()
        try:
            result_words = self.aes.aes_encipher_block(self.key_words, block_words)
        finally:
            sys.stdout = old_stdout
        
        # Convert result tuple of 4 words back to 16 bytes
        self.result = b''.join(
            word.to_bytes(4, byteorder='big') for word in result_words
        )
        self.state = CoreState.IDLE


class TPM_Core:

    def __init__(self, activation_key_words):
        self.dev_state = DevState.LOCKED
        self.activation_key = [w & 0xFFFFFFFF for w in activation_key_words]
        self.unlocked_shift = []
        self.fail_count = 0
        self.lockout_threshold = 3
        self.vault = keyVault()
        self.aes_core = AESCore()
        self.incoming_fabric_reqs = deque()
        self.outgoing_fabric_resps = deque()

    def receive_cmd(self, cmd, **kwargs):
        self.incoming_fabric_reqs.append((cmd, kwargs))  # Simulate receiving a command from the data fabric

    def step(self):
        if not self.incoming_fabric_reqs:
            return  # no commands from fabric, do nothing
        cmd, kwargs = self.incoming_fabric_reqs.popleft()  # Get the next command from the fabric
        self.outgoing_fabric_resps.append(self._handle_cmd(cmd, **kwargs))  # Handle the command and prepare a response

    def _handle_cmd(self, cmd, **kwargs):
        if self.dev_state == DevState.TRAPPED:
            if cmd == CMD.STATUS:
                return Response(ok=True, code="TRAPPED", data={"fail_count": self.fail_count})
            elif cmd == CMD.ZEROIZE:
                self._zeroize()
                self.dev_state = DevState.LOCKED
                return Response(ok=True, code="ZEROIZED")
            return Response(ok=False, code="DEVICE TRAPPED, only STATUS and ZEROIZE commands are accepted")

        if cmd == CMD.STATUS:
            return Response(True, "OK", {
                "dev_state": self.dev_state.name,
                "fail_count": self.fail_count,
                "key_committed": self.vault.key_committed,
                "aes_busy": self.aes_core.state.name,
                "has_result": self.aes_core.result is not None,
            })

        if cmd == CMD.ZEROIZE:
            self._zeroize()
            self.dev_state = DevState.LOCKED
            return Response(ok=True, code="ZEROIZED")

        elif self.dev_state == DevState.LOCKED or self.dev_state == DevState.UNLOCKED_SHIFT:
            # Only allow UNLOCK_WORD commands in these states
            if cmd != CMD.UNLOCK_WORD:
                return Response(ok=False, code="DEVICE LOCKED, only UNLOCK_WORD command is accepted")

            word = kwargs.get("word")
            if word is None:
                return Response(ok=False, code="MISSING WORD ARGUMENT")

            self.dev_state = DevState.UNLOCKED_SHIFT
            self.unlocked_shift.append(word & 0xFFFFFFFF)

            if len(self.unlocked_shift) < 4:
                return Response(ok=True, code="UNLOCK_WORD ACCEPTED, MORE WORDS NEEDED", data={"shift_count": len(self.unlocked_shift)})

            if self.unlocked_shift == self.activation_key:
                self.dev_state = DevState.UNLOCKED
                self.unlocked_shift = []
                self.fail_count = 0
                return Response(ok=True, code="DEVICE UNLOCKED")
            else:
                self.unlocked_shift = []
                self.fail_count += 1
                if self.fail_count >= self.lockout_threshold:
                    self.dev_state = DevState.TRAPPED
                    return Response(ok=False, code="DEVICE TRAPPED DUE TO POTENTIAL ATTACK")
                self.dev_state = DevState.LOCKED
                return Response(ok=False, code="UNLOCK FAILED, DEVICE LOCKED")

        elif self.dev_state == DevState.UNLOCKED:
            try:
                if cmd == CMD.LOAD_KEY_WORD:
                    idx = kwargs["idx"]
                    word = kwargs["word"]
                    self.vault.load_word(idx, word)
                    return Response(ok=True, code=f"KEY WORD {idx} LOADED")

                if cmd == CMD.COMMIT_KEY:
                    if not self.vault.commit():
                        return Response(ok=False, code="KEY COMMIT FAILED: invalid key length")
                    self.aes_core.init_key(self.vault.get_key_words())
                    return Response(ok=True, code="KEY COMMITTED")

                if cmd == CMD.ENCRYPT_BLOCK:
                    if not self.vault.key_committed:
                        return Response(ok=False, code="KEY NOT COMMITTED, CANNOT START ENCRYPTION")
                    block = kwargs.get("block")
                    if block is None or len(block) != 16:
                        return Response(ok=False, code="INVALID BLOCK, MUST BE 16 BYTES")
                    self.aes_core.encrypt(block)
                    return Response(ok=True, code="ENCRYPTION STARTED")

                if cmd == CMD.READ_RESULT:
                    if self.aes_core.result is None:
                        return Response(ok=False, code="NO RESULT AVAILABLE")
                    result = self.aes_core.result
                    self.aes_core.result = None  # Clear the result after reading
                    return Response(ok=True, code="ENCRYPTION RESULT", data={"result": result})

                return Response(ok=False, code="UNKNOWN COMMAND")

            except Exception as e:
                return Response(ok=False, code=f"ERROR PROCESSING COMMAND: {str(e)}")
        else:
            return Response(ok=False, code="INVALID DEVICE STATE")

    def _zeroize(self):
        self.vault.zeroize()
        self.dev_state = DevState.LOCKED
        self.unlocked_shift = []
        self.fail_count = 0
        self.aes_core.result = None
        self.aes_core.key_words = None

    def read_resp(self):
        return self.outgoing_fabric_resps.popleft() if self.outgoing_fabric_resps else None  # Simulate sending a response back on the data fabric


if __name__ == "__main__":
    # Example activation key (4 words)
    act = [0xdeadbeef, 0xcafebabe, 0x12345678, 0x0badf00d]
    dev = TPM_Core(act)

    def do(cmd, **kw):
        dev.receive_cmd(cmd, **kw)
        dev.step()
        resp = dev.read_resp()
        print(cmd.name, kw, "->", resp)
        return resp

    # Try encrypt while locked
    do(CMD.ENCRYPT_BLOCK, block=b"\x00"*16)

    # Wrong unlock attempts
    for _ in range(3):
        do(CMD.UNLOCK_WORD, word=0x0)
        do(CMD.UNLOCK_WORD, word=0x0)
        do(CMD.UNLOCK_WORD, word=0x0)
        do(CMD.UNLOCK_WORD, word=0x0)

    # Now trapped; zeroize resets to locked
    do(CMD.STATUS)
    do(CMD.ZEROIZE)
    do(CMD.STATUS)

    # Correct unlock
    for w in act:
        do(CMD.UNLOCK_WORD, word=w)

    # Load a dummy key + commit
    do(CMD.LOAD_KEY_WORD, idx=0, word=0x00112233)
    do(CMD.LOAD_KEY_WORD, idx=1, word=0x44556677)
    do(CMD.LOAD_KEY_WORD, idx=2, word=0x8899aabb)
    do(CMD.LOAD_KEY_WORD, idx=3, word=0xccddeeff)
    do(CMD.COMMIT_KEY)

    # Encrypt + read result
    do(CMD.ENCRYPT_BLOCK, block=b"\x00"*16)
    result = do(CMD.READ_RESULT)
    
    if result.ok:
        print("\nEncryption successful!")
        print(f"Ciphertext (hex): {result.data['result'].hex()}")

# EOF
