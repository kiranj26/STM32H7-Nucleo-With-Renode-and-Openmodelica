model RC_Equations "RC low-pass charged by a 3.3 V step, written as one ODE"
  import Modelica.Units.SI;

  parameter SI.Resistance R(min = 0) = 1e3 "Series resistor";
  parameter SI.Capacitance C(min = 0) = 1e-6 "Capacitor";
  parameter SI.Voltage V0 = 3.3 "Source voltage, applied from t = 0";
  final parameter SI.Time tau = R*C "Time constant (1 ms)";

  SI.Voltage v(start = 0, fixed = true) "Capacitor voltage (explicit initial condition)";
  SI.Current i "Charging current through R";
equation
  // Kirchhoff: the same current flows through R and into C
  i = (V0 - v)/R;
  C*der(v) = i;

  annotation(
    experiment(StartTime = 0, StopTime = 0.005, Tolerance = 1e-6, Interval = 1e-5),
    Documentation(info = "<html>
<p>P0 milestone 6, text version. One state <code>v</code>; the circuit law written by hand:
<code>C dv/dt = (V0 - v)/R</code>, with <code>v(0) = 0</code>.</p>
<p>Assumptions: ideal resistor and capacitor, ideal 3.3 V source switched on at t = 0,
no load on the capacitor. Analytic solution: <code>v(t) = V0 (1 - exp(-t/tau))</code>,
<code>tau = R C = 1 ms</code>; StopTime = 5 tau.</p>
<p>Compared against <code>RC_Graphical</code> (same circuit from Modelica Standard
Library components) by <code>scripts/p0.mos</code> + <code>scripts/rc_compare.py</code>.</p>
</html>"));
end RC_Equations;
