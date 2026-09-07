import numpy as np

class CapsuleRCSController:
    def __init__(self):
        # Vehicle properties from capsule_specs.json
        self.mass_kg = 45000.0
        self.radius_m = 9.25
        self.max_thrust_per_nozzle_n = 25000.0  # 25 kN
        
        # Calculate spherical hollow shell moment of inertia matrix (I_xx, I_yy, I_zz)
        # I = (2/3) * M * R^2
        self.inertia = (2.0 / 3.0) * self.mass_kg * (self.radius_m ** 2)
        
        # Define 3D Position Vectors for the 8 RCS thruster blocks relative to Center of Mass
        # [X, Y, Z] positions normalized on the capsule's outer radius boundary
        self.thruster_positions = {
            "EQ_0":   np.array([self.radius_m, 0.0, 0.0]),
            "EQ_90":  np.array([0.0, self.radius_m, 0.0]),
            "EQ_180": np.array([-self.radius_m, 0.0, 0.0]),
            "EQ_270": np.array([0.0, -self.radius_m, 0.0]),
            "ZENITH": np.array([0.0, 0.0, self.radius_m]),
            "NADIR":  np.array([0.0, 0.0, -self.radius_m])
        }

    def calculate_maneuver_forces(self, target_linear_accel, target_angular_accel):
        """
        Translates raw physics maneuvering targets into localized force commands.
        target_linear_accel: np.array([ax, ay, az]) in m/s^2
        target_angular_accel: np.array([alpha_x, alpha_y, alpha_z]) in rad/s^2
        """
        # F = m * a
        required_force_n = self.mass_kg * np.array(target_linear_accel)
        
        # Tau = I * alpha
        required_torque_nm = self.inertia * np.array(target_angular_accel)
        
        commands = {}
        
        # 1. Linear Translation Allocation Profile
        if required_force_n[2] < 0:
            # High-output Nadir deceleration de-orbit burn
            commands["NADIR_BURN_FORCE_N"] = min(abs(required_force_n[2]), self.max_thrust_per_nozzle_n * 4)
        elif required_force_n[2] > 0:
            commands["ZENITH_BOOST_FORCE_N"] = min(required_force_n[2], self.max_thrust_per_nozzle_n * 4)
            
        # 2. Angular Rotation Allocation Profile (Cross-Product Torque: Tau = r x F)
        # Pitch / Roll tracking handled via the equatorial ring clusters
        if abs(required_torque_nm[0]) > 0: # Roll Torque axis
            commands["ROLL_COUPLING_N"] = min(abs(required_torque_nm[0]) / self.radius_m, self.max_thrust_per_nozzle_n)
            
        return {
            "requested_linear_vector_n": required_force_n.tolist(),
            "requested_torque_vector_nm": required_torque_nm.tolist(),
            "allocated_actuator_outputs": commands
        }

# Instantiate flight controller software tracking state
if __name__ == "__main__":
    controller = CapsuleRCSController()
    # Simulate a high-G orbital evasion de-orbit burn command
    flight_telemetry = controller.calculate_maneuver_forces(
        target_linear_accel=[0.0, 0.0, -2.5],     # De-orbit braking push down
        target_angular_accel=[0.05, 0.0, 0.0]     # Re-entry orientation pitch correction
    )
    print(f"Flight Engine Calculated Torques: {flight_telemetry}")
