model RC_Graphical "RC low-pass charged by a 3.3 V step, built from MSL components"
  import Modelica.Units.SI;

  parameter SI.Resistance R(min = 0) = 1e3 "Series resistor";
  parameter SI.Capacitance C(min = 0) = 1e-6 "Capacitor";
  parameter SI.Voltage V0 = 3.3 "Source voltage, applied from t = 0";

  Modelica.Electrical.Analog.Sources.ConstantVoltage source(V = V0)
    annotation(Placement(transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R = R)
    annotation(Placement(transformation(origin = {-20, 30}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Capacitor capacitor(C = C, v(start = 0, fixed = true))
    annotation(Placement(transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation(Placement(transformation(origin = {-20, -40}, extent = {{-10, -10}, {10, 10}})));

  SI.Voltage v = capacitor.v "Capacitor voltage (same name as in RC_Equations, for comparison)";
equation
  connect(source.p, resistor.p)
    annotation(Line(points = {{-60, 10}, {-60, 30}, {-30, 30}}, color = {0, 0, 255}));
  connect(resistor.n, capacitor.p)
    annotation(Line(points = {{-10, 30}, {20, 30}, {20, 10}}, color = {0, 0, 255}));
  connect(capacitor.n, ground.p)
    annotation(Line(points = {{20, -10}, {20, -30}, {-20, -30}}, color = {0, 0, 255}));
  connect(source.n, ground.p)
    annotation(Line(points = {{-60, -10}, {-60, -30}, {-20, -30}}, color = {0, 0, 255}));

  annotation(
    experiment(StartTime = 0, StopTime = 0.005, Tolerance = 1e-6, Interval = 1e-5),
    Diagram(coordinateSystem(extent = {{-100, -60}, {60, 60}})),
    Documentation(info = "<html>
<p>P0 milestone 6, component version: the same circuit as <code>RC_Equations</code>,
assembled from Modelica Standard Library 4.0.0 components and <code>connect()</code>
equations. The compiler derives the circuit equations (Kirchhoff current and voltage
laws) from the connections; nothing is written by hand.</p>
<p>The Placement/Line annotations make the model render as a schematic in OMEdit.
It was written as text (no display in the devcontainer), not drawn in the OMEdit GUI.</p>
<p>Assumptions and analytic solution: see <code>RC_Equations</code>.</p>
</html>"));
end RC_Graphical;
