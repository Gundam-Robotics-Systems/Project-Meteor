// ==========================================
// GUNDAM SATELLITE RE-ENTRY CAPSULE MODEL
// Project: Operation Meteor - Pod Hardware
// ==========================================

$fn = 100; // Mesh resolution smoothness

// --- Parameterized Dimensions (Meters scaled to mm for CAD) ---
capsule_diameter = 185;       // 18.5m Actual Diameter
shell_thickness  = 4;         // Hull wall thickness
thruster_count   = 8;         // Equatorial/Polar clusters
thruster_radius  = 12;        // Size of thruster mounts
nozzle_aperture  = 3;         // RCS nozzle exhaust radius

module main_capsule_hull() {
    difference() {
        // Outer spherical armored shell
        sphere(r = capsule_diameter / 2);
        
        // Inner hollow payload envelope for Mobile Suit cradle
        sphere(r = (capsule_diameter / 2) - shell_thickness);
        
        // Visual indicator of clamshell splitting seam
        cube([capsule_diameter + 5, 0.5, capsule_diameter + 5], center = true);
    }
}

module rcs_thruster_housing() {
    difference() {
        // External housing block jutting from the sphere
        cylinder(h = thruster_radius * 1.5, r1 = thruster_radius, r2 = thruster_radius * 0.7, center = false);
        
        // 4x Quad-Aperture exhaust nozzles inside each housing block
        translate([thruster_radius * 0.4, 0, thruster_radius * 0.5])
            cylinder(h = thruster_radius * 1.5, r = nozzle_aperture, center = false);
        translate([-thruster_radius * 0.4, 0, thruster_radius * 0.5])
            cylinder(h = thruster_radius * 1.5, r = nozzle_aperture, center = false);
        translate([0, thruster_radius * 0.4, thruster_radius * 0.5])
            cylinder(h = thruster_radius * 1.5, r = nozzle_aperture, center = false);
        translate([0, -thruster_radius * 0.4, thruster_radius * 0.5])
            cylinder(h = thruster_radius * 1.5, r = nozzle_aperture, center = false);
    }
}

module complete_assembly() {
    // 1. Render Base Armor Hull
    color("LightGray", 0.9) main_capsule_hull();
    
    // 2. Render Forward Heat Shield (Ablative Hemisphere Section)
    color("DimGray", 1.0) intersection() {
        sphere(r = (capsule_diameter / 2) + 0.5); 
        translate([0, 0, -capsule_diameter / 2]) 
            cube([capsule_diameter + 2, capsule_diameter + 2, capsule_diameter], center = true);
    }
    
    // 3. Distribute Symmetrical RCS Clusters (Equatorial Array)
    color("SteelBlue") {
        for (i = [0 : thruster_count - 1]) {
            rotate([0, 0, i * (360 / thruster_count)])
            translate([(capsule_diameter / 2) - 2, 0, 0])
            rotate([0, 90, 0])
            rcs_thruster_housing();
        }
        
        // 4. Polar Zenith Thruster (Top Escape & Translation Maneuvering)
        translate([0, 0, (capsule_diameter / 2) - 2])
        rotate([0, 0, 0])
        rcs_thruster_housing();
        
        // 5. Polar Nadir Thruster (Bottom De-orbit Deceleration Burn)
        translate([0, 0, -(capsule_diameter / 2) + 2])
        rotate([180, 0, 0])
        rcs_thruster_housing();
    }
}

// Instantiate the full model build tree
complete_assembly();
