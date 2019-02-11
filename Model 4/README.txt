Implementing value iteration in 1D ( 1 choice, 1 state)
Also trying to avoid too many global variables.

EGM can deal with significantly less grid points. The accuracy of EGM is basically unchanged going from 20 points to 2000.
VFI requires 300 ish points to get utility equal to EGM to 7sf. I currently have it set to 100 points which gives 4sf accuracy.
