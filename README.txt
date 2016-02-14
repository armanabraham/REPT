01 Sep 2010, Arman
-------------------
REPT (Rapid Estimation of Phosphene Thresholds) uses a Bayesian adaptive staircase to automatically estimate phosphene thresholds. REPT uses Rapid2 Matlab toolbox to programmatically vary the pulse intensity of Magstim Rapid2 stimulator via a serial connection, which can be downloaded from https://github.com/armanabraham/Rapid2 .


Installation Instructions: 
--------------------------
1. Download and install Rapid2 toolbox from http://www.psych.usyd.edu.au/tmslab/rapid2andrept.html
2. Download and install Psychtoolbox (version 3 and above) from http://psychtoolbox.org/wikka.php?wakka=FencsikPsychtoolboxDownload
2. Install REPT into a directory called 'REPT' on your computer. 
3. Add 'REPT' directory to Matlab path


Usage Instructions
------------------
1. Ensure that the stimulator and computer are connected via a serial connection. 
2. Run REPT_main.m. A GUI should appear which would let you control the stimulator and run the staircase to estimate the phosphene threshold. 

NOTE: More details about REPT will be provided in a companion publication which will be distributed under 'open access' for anyone to download. 


Software and System Requirements
-------------------
1. The library was developed and tested under Windows XP and Windows 7. Mac OS X can also be used provided you have a "USB to serial" adapter.  
2. Matlab version: 7.7 (R2008b) or above. It might work with older versions but I haven't had chance to test. 
3. Computer: Fast processor speed starting from 2GHz and at least 1.5Gb of RAM.   


Contact
-------
For questions, suggestions and bug reports please email Arman on: arman.abrahamyan@sydney.edu.au. 


License
-------
REPT is distributed under GNU General License and details are provided in License.txt file. 


Download
--------
The latest version of REPT can be downloaded from: http://www.psych.usyd.edu.au/tmslab/rapid2andrept.html 


DISCLAIMER 
----------
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
