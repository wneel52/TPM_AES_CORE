import serial
import time
from dataclasses import dataclass

serial_port = "COM3" # update to match your platform
baud_rate = 115200
timeout = 1.0
boot_delay = 2*timeout
step_delay = 0.1

stage1_candidates = [0x0000,0x0123,0xFFFF,0xEEFF]
stage2_candidates = [0x0000,0x0123,0xFFFF,0x4444]
stage3_candidates = [0x0000,0x0123,0xFFFF,0x5678]

stage1_good = 0xEEFF
stage2_good = 0x4444
stage3_good = 0x5678

@dataclass
class Status:
    header : int
    raw : int
    unlocked : int
    aes_enable : int
    auth_zeroize : int
    key_sel : int
    state_debug : int

    @classmethod
    def from_bytes(cls, data: bytes):
        if len(data) != 2:
            raise ValueError("Error: Expected 2 bytes of data, got {}".format(len(data)))
        if data[0] != 0xD0:
            raise ValueError("Error: Expected header byte 0xD0, got 0x{:02X}".format(data[0]))
        s = data[1]
        return cls(
            header=data[0],
            raw=s,
            unlocked=s & 0x1,
            aes_enable=(s >> 1) & 0x1,
            auth_zeroize=(s >> 2) & 0x1,
            key_sel=(s >> 3) & 0x3,
            state_debug= (s >> 5) & 0x3
        )

    def short(self) -> str:
        return(
            f"raw=0x{self.raw:02X}, "
            f"unlocked={self.unlocked}, "
            f"aes_enable={self.aes_enable}, "
            f"auth_zeroize={self.auth_zeroize}, "
            f"key_sel={self.key_sel}, "
            f"state_debug={self.state_debug}"
        )
    

class platform_key_validation_driver:
    def __init__(self, port: str, baud: int, timeout: float):
        self.serial_port = serial.Serial(port,baud,timeout=timeout)
        time.sleep(boot_delay)

    def close(self):
        if self.serial_port.is_open:
           self.serial_port.close()
    
    def _read_exact(self, n: int) -> bytes:
        data = self.serial_port.read(n)
        if len(data) != n:
            raise ValueError("Error: Expected {} bytes, got {}".format(n, len(data)))   
        return data
    
    def read_status(self):
        self.serial_port.write(bytes([0xA3]))
        data = self._read_exact(2)
        return Status.from_bytes(data)
    
    def load_key(self, key:int) -> str:
        if not(0 <= key <= 0xFFFF):
            raise ValueError("Error: Key must be a unsigned 16-bit value (0-65535)")
        hi  = (key >> 8) & 0xFF
        lo = key & 0xFF
        self.serial_port.write(bytes([0xA1, hi, lo]))
        ack = self._read_exact(1)
        return ack.hex(" ")
    
    def compare(self) -> str:
        self.serial_port.write(bytes([0xA2]))
        ack = self._read_exact(1)
        return ack.hex(" ")
    
    def zeroize(self) -> str:
        self.serial_port.write(bytes([0xA4]))
        ack = self._read_exact(1)
        return ack.hex(" ")
    
    def commit_illegal(self) -> str:
        self.serial_port.write(bytes([0xA5]))
        ack = self._read_exact(1)
        return ack.hex(" ")
    
    def reset_to_init(self) -> str:
        ack = self.zeroize()
        time.sleep(step_delay)
        status = self.read_status()
        print(f"zeroize ack:{ack or '<none>'} -> ({status.short()})")
        return status
        
    def apply_key_and_compare(self, key):
        load_ack = self.load_key(key)
        time.sleep(step_delay)

        cmp_ack = self.compare()
        time.sleep(step_delay)

        status = self.read_status()

        print(
            f"key=0x{key:04X} "
            f"load_ack={load_ack or '<none>'} "
            f"cmp_ack={cmp_ack or '<none>'} "
            f"status=({status.short()})"
        )

        return status

    def drive_stage2(self) -> Status:
        self.reset_to_init()
        status = self.apply_key_and_compare(stage1_good)
        return status
    
    def drive_stage3(self) -> Status:
        self.reset_to_init()
        status1 = self.apply_key_and_compare(stage1_good)
        if status1.key_sel != 1:
            print("Error: Stage 1 failed, cannot proceed to stage 2")
            return status1
        status2 = self.apply_key_and_compare(stage2_good)
        if status2.key_sel != 2:
            print("Error: Stage 2 failed, cannot proceed to stage 3")
            return status2
        return status2
    
    def test_stage1_candidates(self):
        print("Testing stage 1 candidates...")
        for key in stage1_candidates:
            self.reset_to_init()
            self.apply_key_and_compare(key)
            verdict = "GOOD" if key == stage1_good else "BAD"
            print(f"Stage 1 candidate: 0x{key:04X} -> {verdict}")
    
    def test_stage2_candidates(self):
        print("Testing stage 2 candidates...")
        for key in stage2_candidates:
            self.drive_stage2()
            status = self.apply_key_and_compare(key)
            print(self.classify_stage2(status))

    def test_stage3_candidates(self):
        print("Testing stage 3 candidates...")
        for key in stage3_candidates:
            self.drive_stage3()
            status = self.apply_key_and_compare(key)
            print(f"Stage 3 candidate: 0x{key:04X} -> {self.classify_stage3(status)}")

    @staticmethod
    def classify_stage1(status: Status) -> str:
        if status.unlocked:
            return "error: device should not be unlocked at stage 1"
        if status.aes_enable:
            return "error: AES should not be enabled at stage 1"
        if status. key_sel == 1 and status.state_debug == 1:
            return "advanced to stage 2"
        if status.key_sel == 0 and status.state_debug == 0:
            return "reset to init"
        return "error: unexpected status at stage 1"
    
    @staticmethod
    def classify_stage2(status: Status) -> str:
        if status.unlocked:
            return "error: device should not be unlocked at stage 2"
        if status.aes_enable:
            return "error: AES should not be enabled at stage 2"
        if status.key_sel == 2 and status.state_debug == 2:
            return "advanced to stage 3"
        if status.key_sel == 0 and status.state_debug == 0:
            return "reset to init"
        if status.key_sel == 1 and status.state_debug == 1:
            return "remained at stage 2"
        return "error: unexpected status at stage 2"
    
    @staticmethod
    def classify_stage3(status):
        if status.unlocked and status.aes_enable:
            return "unlocked"
        if status.key_sel == 0 and status.state_debug == 0:
            return "reset to init"
        return "unexpected state"
    
def main():
    driver = platform_key_validation_driver(serial_port, baud_rate, timeout)
    try:
        print("Initial status:", driver.read_status().short())
        driver.test_stage1_candidates()
        driver.test_stage2_candidates()
        driver.test_stage3_candidates()
        # drive unlock sequence
        driver.drive_stage3()
        driver.apply_key_and_compare(stage3_good)
        time.sleep(5 * step_delay) # observe unlocked state on LEDs
        driver.zeroize() # zeroize to lock again and observe on LEDs
        print("Final status:", driver.read_status().short())
    finally:
        driver.close()

if __name__ == "__main__":
    main()