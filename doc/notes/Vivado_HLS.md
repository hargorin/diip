Vivado HLS Pragmas

RESOURCE MulnS: N-stage pipelined multiplier
	--> Bei eine Multiplikation verwendet, um das timing zu verkleinern
	(Pipeline Stages > 1 cause registers to be
 	inserted between input and output up 
	to the optimum pipeline stages value. Adding more registers improves 
	achievable clock speed while increasing latency.)

RESOURCE DivnS:
	--> 

ARRAY_RESHAPE (cyclic): teilt das array in mehrere blöcke auf
	--> Beim array "pixel" verwendet, damit bei der funktion "cal_variance" das pragma PIPELINE angewendet werden. Dabei ist man um den faktor cyclic schneller.

DEPENDENCE inter RAW: Abhängigkeit von der Variable und zwischen loops
	--> Wurde bei n_Mean und n_Var angewendet, da diese zuerst berechned werden müssen und erst danach gelesen.
	(eventuell brauchts diese "dependence" gar nicht)!!!!
