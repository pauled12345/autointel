import obd
from datetime import datetime, timezone


class OBDReader:
    """Wraps python-obd to connect to an ELM327 adapter over Bluetooth (RFCOMM/serial),
    read stored DTCs (fault codes), and pull live sensor PIDs."""

    def __init__(self, port: str | None = None):
        # port=None lets python-obd auto-detect the serial device.
        self.connection = obd.OBD(portstr=port, fast=False)

    def is_connected(self) -> bool:
        return self.connection.is_connected()

    def read_fault_codes(self) -> list[dict]:
        response = self.connection.query(obd.commands.GET_DTC)
        codes = []
        if response and not response.is_null():
            for code, description in response.value:
                codes.append({"code": code, "raw_description": description})
        return codes

    def clear_fault_codes(self) -> bool:
        response = self.connection.query(obd.commands.CLEAR_DTC)
        return not response.is_null()

    def read_live_pids(self, pids: list[str] | None = None) -> list[dict]:
        """Reads a default (or custom) set of live sensor PIDs."""
        default_pids = ["RPM", "SPEED", "COOLANT_TEMP", "ENGINE_LOAD", "THROTTLE_POS"]
        target_pids = pids or default_pids
        readings = []
        now = datetime.now(timezone.utc)

        for pid_name in target_pids:
            command = getattr(obd.commands, pid_name, None)
            if command is None:
                continue
            response = self.connection.query(command)
            if response and not response.is_null():
                readings.append({
                    "pid": pid_name,
                    "value": response.value.magnitude if hasattr(response.value, "magnitude") else response.value,
                    "unit": str(response.value.units) if hasattr(response.value, "units") else None,
                    "recorded_at": now,
                })
        return readings

    def close(self):
        self.connection.close()
