Created Dec, 2018

The simulator was design to test Radrio Frequency Interference (RFI) Mitigation algorithms on simulated data
The simulator uses a XML files as a config along with text files for ephemeris data and antenna positions. 
Antennas are recognized by MIRIAD number. 

Currently, only output of the simulator is ATA Data binary file (description in ATA_header_description.txt)

If you are using simulator for scientific papers, please cite the work;
J. S. Kulpa, W. C. Barott, "SIGNAL SIMULATOR FOR RFI MITIGATION ALGORITHMS TESTING", presented during GlobalSIP 2018 Conference. 
(https://ieeexplore.ieee.org/document/8646411)

Please note that some files depends on leap second count.
Please check ATATools.Misc.TAI2UTC and ATATools.Misc.UTC2TAI files for correctnes. 
Last leap second update: Dec 2016

This work was supported by the National Science Foundation under grant 1547420.
