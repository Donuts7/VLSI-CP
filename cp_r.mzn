include "cumulative.mzn";
%include "diffn_k.mzn";
include "diffn.mzn";


% width of the plate 
int: width;

% number of circuits to be fitted
int: n_circuits;

% calculated max_height of the plate
int: max_height;

% max max_height of a single circuit
int: max_y;

% horizontal  and vertical dimension of circuits
array[1..n_circuits] of 1..width: circuit_x;
array[1..n_circuits] of 1..max_y: circuit_y;

% additional variables for the rotational model
array[1..n_circuits] of var bool: rotated;
array[1..n_circuits,1..2] of var int: dimensions ;

% the dimensions here are swapped if the circuit is rotated, otherwise they remain the same
constraint forall(i in 1..n_circuits) (if rotated[i] then dimensions[i,1] = circuit_y[i] /\ dimensions[i,2] = circuit_x[i] else dimensions[i,1] = circuit_x[i]  /\ dimensions[i,2] = circuit_y[i] endif);

% assignment of the dimensions values to the arrays rot_x and rot_y, that will substitute coord_x and coord_y from now on
set of int: interval = 1..max(max_y,max(circuit_x));
array[1..n_circuits] of var interval: rot_x = [dimensions[i,1] | i in 1..n_circuits];
array[1..n_circuits] of var interval: rot_y = [dimensions[i,2] | i in 1..n_circuits];

% area of circuits
array[1..n_circuits] of int: area = [ circuit_x[i] * circuit_y[i] | i in 1..n_circuits];

% these arrays contain the coordinates of the bottom left corner of each circuit
array[1..n_circuits] of var 0..(width - arg_min(circuit_x)): coord_x;
array[1..n_circuits] of var 0..(max_height - arg_min(circuit_y)): coord_y;

% biggest square circuit  
var int: li = max([area[i] | i in 1..n_circuits where(circuit_y[i] == circuit_x[i])]);
var int: biggest_circuit_square = max([i | i in 1..n_circuits where (area[i] == li)]);

% simmetry breaking constraint: the biggest square circuit is placed on the top right corner of the plate
constraint  coord_x[biggest_circuit_square] == (width - circuit_x[biggest_circuit_square]) /\ coord_y[biggest_circuit_square] == (max_height - circuit_y[biggest_circuit_square]);


% resource allocation constraints, see report for more
constraint cumulative(coord_y, rot_y, rot_x, width);
constraint cumulative(coord_x, rot_x, rot_y, max_height);

% constraints to make each circuit lie inside the boundaries of the plate
constraint forall(i in 1..n_circuits-1) ([coord_x[i],coord_y[i]] != [coord_x[i+1],coord_y[i+1]] );

% non-overlapping constraint from MiniZinc Handbook
constraint forall(i in 1..n_circuits) (coord_x[i]+ rot_x[i] <= width );
constraint forall(i in 1..n_circuits) (coord_y[i]+ rot_y[i] <= max_height );

constraint diffn(coord_x, coord_y, rot_x, rot_y);


% redundant constraint: if two different circuits have the same horizontal dimension and the sum of their vertical dimension is equal to the max_height of the plate, place them in the same column
constraint forall(i in 1..n_circuits,j in 1..n_circuits) (if rot_x[i] == rot_x[j] /\ rot_y[i] + rot_y[j] == max_height /\ i != j /\ n_circuits != 8 /\ n_circuits != 10 then coord_x[i] = coord_x[j] endif);


% variable selection methods, these changed for every test
%ann: search_ann_x = int_search(coord_x, first-fail, indomain_min);
%ann: search_ann_y =  int_search(coord_y, first-fail, indomain_min);

ann: search_ann_x = int_search(coord_x, occurrence, indomain_min);
ann: search_ann_y =  int_search(coord_y, occurrence, indomain_min);

ann: restart_ann = restart_luby(100);
%ann: restart_ann = restart_constant(100)
%ann: restart_ann = restart_geometric(1.5,100)
%ann: restart_ann = restart_linear(100)

solve :: search_ann_x
      :: search_ann_y
      :: restart_ann
         satisfy;


output["\(width) \(max_height)\n\(n_circuits)\n"] ++ ["\(rot_x[i]) \(rot_y[i]) \(coord_x[i]) \(coord_y[i])" ++ "\n" | i in 1..n_circuits];