% Modification of Ben Moll's: http://www.princeton.edu/~moll/HACTproject/option_simple_LCP.m
%For algebra and equation numbers, see the 'operator_discretization_finite_differences.pdf'

%This function takes a grid on [x_min, x_max] and discretizing a general diffusion defined by the following SDE
%d x_t = mu(x_t)dt + sigma(x_t)^2 dW_t
%Subject to reflecting barrier at x_min and x_max

%Pass in the vector of the grid x, and the vectors of mu and sigma_2 at the nodes, and returns a sparse discretized operator.
function A = discretize_univariate_diffusion(x, mu, sigma_2)

	I = length(x); %number of grid variables for x

	%Check if the grid is uniform
	tol = 1E-10; %Tolerance for seeing if the grid is uniform
	Delta_p = diff(x); %(1) Find distances between grid points.
	if(abs(min(Delta_p) - max(Delta_p)) < tol) %i.e. a uniform grid within tolerance
		Delta = x(2)-x(1); % (1)
		Delta_2 = Delta^2; %Just squaring the Delta for the second order terms in the finite differences.

		%% Construct sparse A matrix
		mu_m = min(mu,0); %General notation of plus/minus.
		mu_p = max(mu,0); 		
		X = - mu_m/Delta + sigma_2/(2*Delta_2); % (7)
		Y = - mu_p/Delta + mu_m/Delta - sigma_2/Delta_2; % (8)
		Z =  mu_p/Delta + sigma_2/(2*Delta_2); %(9)
		
		%Creates a tri-diagonal matrix.  See the sparse matrix tricks documented below
		A = spdiags([[X(2:I); 0] Y [0; Z(1:I - 1)]], [-1 0 1], I,I);% (10) interior is correct.  Corners will require adjustment    
		
		%Manually adjust the boundary values at the corners.
		A(1,1) = Y(1) + X(1); %Reflecting barrier, (10) and (5)
		A(I,I) = Y(I) + Z(I); %Reflecting barrier,  (10) and (6)
	else
		A = NaN;
		assert(false, 'not yet supported');
	end	
end	

%Sparse matrix trick: spdiags takes vector(s) and offset(s).  It returns the vector(s) in sparse a diagonal matrix where the diagonal is offset by the other argument.
%For example:
% norm(spdiags([1;2;3], 0, 3, 3) - diag([1 2 3]), Inf) % on the true diagonal, offset 0.
% norm(spdiags([2;3;9999], -1, 3, 3)- [0 0 0; 2 0 0; 0 3 0], Inf) %on the diagonal below.  Note that the last element is skipped since only 2 points on off diagonal.
% norm(spdiags([9999;2;3], 1, 3, 3)- [0 2 0; 0 0 3; 0 0 0], Inf) %on the diagonal above.  Note that the first element is skipped since only 2 points on off diagonal.	
%Alternatively this can be done in a single operation to form a tridiagonal matrix by stacking up the arrays, where the 2nd argument is a list of the offsets to apply the columns to)
%Can add them as sparse matrices.  For example, the above code is equivalent to %A = spdiags(Y, 0, I, I) + spdiags(X(2:I),-1, I, I) + spdiags([0;Z(1:I-1)], 1, I, I);