function model = getlnmodel(z_fit, y_fit)
% function model = getlnmodel(z_fit, y_fit)

fitdata.y_t = y_fit;
fitdata.z_t = z_fit;

% initialise fit params
fitparams.restarts = 6;
fitparams.options = optimset('Algorithm', 'sqp', 'Display', 'off');
fitparams.model = @lnmodel;

% data driven starting values (could also be used as priors)
zrange = iqr(z_fit);
zmean = mean(z_fit);
yrange = iqr(y_fit);
ymin = prctile(y_fit, 25);

%a ~ Exp(ymin + 0.05) 
%b ~ Exp(yrange * 2) % not using *2
%c ~ N(zmean, zrange ^ 2)
%d ~ Exp(0.1 * zrange)
fitparams.x0fun = {@() exprnd(ymin+0.05) @() exprnd(yrange) ...
       			     @() (randn*zrange)+zmean @() exprnd(0.1*zrange)};

% constraints
y_min = min(y_fit);
y_max = max(y_fit);
y_range = range(y_fit);
z_min = min(z_fit);
z_max = max(z_fit);
z_range = range(z_fit);

% bounds are intended to be rather generous
lb = [y_min-y_range 0 z_min-z_range -1000]; % lower bounds
ub = [y_max+y_range 2*y_range z_max+z_range 1000]; % upper bounds

fitparams.params = {[], [], [], [], lb, ub, []};

model = fitmodel3(fitparams, fitdata);

if any(abs(model.params-lb)<eps)
	fprintf('getlnmodel: hit lower bounds:\n');
	fitparams.params
	lb
end

if any(abs(model.params-ub)<eps)
	fprintf('getlnmodel: hit upper bounds\n');
	fitparams.params
	ub
end
