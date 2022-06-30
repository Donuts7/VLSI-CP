include "cumulative.mzn";
%include "diffn_k.mzn";
include "diffn.mzn";


% width of the plate 
int: width;

% number of circuits to be fitted
int: n_circuits;

% calculated height of the plate
int: opt_height;
int: max_height = 2*opt_height;

var opt_height..max_height: height;

% max height of a single circuit
int: max_y;

% horizontal  and vertical dimension of circuits
array[1..n_circuits] of 1..width: circuit_x;
array[1..n_circuits] of 1..max_y: circuit_y;

array[1..n_circuits,1..2] of var int: dimensions ;
%constraint forall(i in 1..n_circuits) (dimensions[i,1] = circuit_x[i] /\ dimensions[i,2] = circuit_y[i]);

% area of circuits
array[1..n_circuits] of int: area = [ circuit_x[i] * circuit_y[i] | i in 1..n_circuits];

% these arrays contain the coordinates of the bottom left corner of each circuit
array[1..n_circuits] of var 0..(width - arg_min(circuit_x)): coord_x;
array[1..n_circuits] of var 0..(max_height - arg_min(circuit_y)): coord_y;

% biggest square circuit  
var int: li = max([area[i] | i in 1..n_circuits where(circuit_y[i] == circuit_x[i])]);
var int: biggest_circuit_square = max([i | i in 1..n_circuits where (area[i] == li)]);

% simmetry breaking constraint: the biggest square circuit is placed on the top right corner of the plate
constraint  if n_circuits <25 then coord_x[biggest_circuit_square] == (width - circuit_x[biggest_circuit_square]) /\ coord_y[biggest_circuit_square] == (height - circuit_y[biggest_circuit_square])endif;

% resource allocation constraints, see report for more
constraint cumulative(coord_y, circuit_y, circuit_x, width);
constraint cumulative(coord_x, circuit_x, circuit_y, height);

% constraints to make each circuit lie inside the boundaries of the plate
constraint forall(i in 1..n_circuits) (coord_x[i]+ circuit_x[i] <= width );
constraint forall(i in 1..n_circuits) (coord_y[i]+ circuit_y[i] <= height );

% non-overlapping constraint from MiniZinc Handbook
constraint diffn(coord_x, coord_y, circuit_x, circuit_y);

% redundant constraint: if two different circuits have the same horizontal dimension and the sum of their vertical dimension is equal to the height of the plate, place them in the same column
constraint forall(i in 1..n_circuits,j in 1..n_circuits) (if circuit_x[i] == circuit_x[j] /\ circuit_y[i] + circuit_y[j] == height /\ i != j /\ n_circuits != 8 /\ n_circuits != 10 then coord_x[i] = coord_x[j] endif);



% variable selection methods, these changed for every test
%ann: search_ann_x = int_search(coord_x, first-fail, indomain_min);
%ann: search_ann_y =  int_search(coord_y, first-fail, indomain_min);

ann: search_ann_x = int_search(coord_x, occurrence, indomain_min);
ann: search_ann_y =  int_search(coord_y, occurrence, indomain_min);

%ann: restart_ann = restart_luby(100);
%ann: restart_ann = restart_constant(100);
ann: restart_ann = restart_geometric(1.5,100);
%ann: restart_ann = restart_linear(100);

solve :: search_ann_x
      :: search_ann_y
      :: restart_ann
         minimize height;
 
 
output["\(width) \(height)\n\(n_circuits)\n"] ++ ["\(circuit_x[i]) \(circuit_y[i]) \(coord_x[i]) \(coord_y[i])\n" | i in 1..n_circuits];