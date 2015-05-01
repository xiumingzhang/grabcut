function BK_UnitTest
% BK_UnitTest   Compile, load, and test the BK_MATLAB library.
%    BK_UnitTest will make sure the wrapper compiles on the target 
%    platform and then exercises the library to look for silly bugs.

    function Assert(cond,msg)   % for older MATLAB without assert()
        if (exist('assert') == 5)
            if (nargin < 2)
                assert(cond);
            else
                assert(cond,msg);
            end
        elseif (~cond)
            if (nargin < 2)
                msg = 'Assertion failed';
            end
            error(msg);
        end
    end

    function D = Sparse2Dense(S)
        [i,j,s] = find(S);
        z = zeros(size(s,1),1);
        D = [i,j,z,s,s,z];  % [i,j,e00,e01,e10,e11]
    end

BK_BuildLib; disp('BuildLib PASSED');
BK_LoadLib;  disp('LoadLib PASSED');


% Basic tests with no Create/Delete
caught=false; try BK_Delete(10);          catch, caught=true; end, Assert(caught,'Expected an exception');
caught=false; try h = BK_Create(-1);      catch, caught=true; end, Assert(caught,'Expected an exception');
caught=false; try h = BK_Create(1,-1);    catch, caught=true; end, Assert(caught,'Expected an exception');
h1 = BK_Create(5);
h2 = BK_Create(3);
Assert(all(BK_ListHandles == [h1; h2]));
BK_Delete(h1);
caught=false; try BK_GetLabeling(h1);     catch, caught=true; end, Assert(caught,'Expected an exception');
caught=false; try BK_Delete(h1);          catch, caught=true; end, Assert(caught,'Expected an exception');
Assert(all(BK_ListHandles == [h2]));
BK_Delete(h2);
Assert(isempty(BK_ListHandles));
caught=false; try BK_Delete(h2);          catch, caught=true; end, Assert(caught,'Expected an exception');
disp('Create/Delete PASSED');
disp('ListHandles PASSED');


% Test with NO costs 
h = BK_Create(3);
e = BK_Minimize(h);
Assert(e == 0);
e = BK_Minimize(h);
Assert(e == 0);
BK_Delete(h);
disp('Expansion-000 PASSED');




% Test with DATA cost only
h = BK_Create(5);
dc = [1 2 5 10 0; 
      3 1 2  5 4];

caught=false; try BK_SetUnary(h,[dc [0 0]']);    catch, caught=true; end, Assert(caught,'Expected an exception');
caught=false; try BK_SetUnary(h,dc(:,1:end-1));  catch, caught=true; end, Assert(caught,'Expected an exception');
caught=false; try BK_SetUnary(h,dc(1:end-1,:));  catch, caught=true; end, Assert(caught,'Expected an exception');

BK_SetUnary(h,dc);
e = BK_Minimize(h);
Assert(e == 9);
Assert(all(BK_GetLabeling(h) == [1 2 2 2 1]'));
BK_Delete(h);

disp('Expansion-D00 PASSED');







% Test with DATA+SMOOTH costs
h = BK_Create();
BK_AddVars(h,5);

caught=false; try BK_SetNeighbors(h,eye(4));              catch, caught=true; end, Assert(caught,'Expected an exception');
caught=false; try BK_SetNeighbors(h,zeros(6));            catch, caught=true; end, Assert(caught,'Expected an exception');

BK_SetUnary(h,dc);
BK_SetNeighbors(h, [0 2 0 0 0;
                          0 0 1 0 0;
                          0 0 0 5 0;
                          0 0 0 0 5;
                          0 0 0 0 0]);

e = BK_Minimize(h);
Assert(e == 15);
Assert(all(BK_GetLabeling(h) == [1 1 2 2 2]'));

disp('Expansion-DS0 (sparse) PASSED');


% Test with DATA+SMOOTH costs
h = BK_Create();
BK_AddVars(h,5);

BK_SetUnary(h,dc);
BK_SetPairwise(h, Sparse2Dense([0 2 0 0 0;
                                0 0 1 0 0;
                                0 0 0 5 0;
                                0 0 0 0 5;
                                0 0 0 0 0]));

e = BK_Minimize(h);
Assert(e == 15);
Assert(all(BK_GetLabeling(h) == [1 1 2 2 2]'));

disp('Expansion-DS0 (dense) PASSED');





nb = sparse([0 5; 0 0;]);

dc1 = [2  0; 
       0  2];

dc2 = [1  0; 
       0  1];
   
%%%%%%%%%%%%
h = BK_Create(2);
BK_SetNeighbors(h,nb);
BK_SetUnary(h,dc1);
eh1 = BK_Minimize(h);
lh1 = BK_GetLabeling(h);
BK_SetUnary(h,dc2);
eh2 = BK_Minimize(h);
lh2 = BK_GetLabeling(h);

%%%%%%%%%%%%
g = BK_Create(2);
BK_SetNeighbors(g,nb);
BK_SetUnary(g,dc2);
eg2 = BK_Minimize(g);
lg2 = BK_GetLabeling(g);

Assert(eh2 == eg2);

BK_Delete(h);
BK_Delete(g);

disp('Dynamic (small) PASSED');





% Test large scale, and incremental data costs DATA+SMOOTH costs
rand('twister', 987+4); % get the same random stream each time
wd = 128; ht = 96;
noise1 = rand([wd,ht])*20;
noise2 = rand([wd,ht])*20;
H = fspecial('disk',5);
noise1 = imfilter(noise1,H,'replicate');
noise2 = imfilter(noise2,H,'replicate');
noise = [noise1(:)';noise2(:)'];
nb = sparse(wd*ht,wd*ht);
for y=1:ht % set up a grid-like neighbourhood, arbitrarily
    for x=1:wd
        if (x < wd), nb((y-1)*wd+x,(y-1)*wd+x+1) = 1; end
        if (y < ht), nb((y-1)*wd+x, y   *wd+x  ) = 1; end
    end
end
distmap = [zeros(ht,wd/2) ones(ht,wd/2)];
distmap = bwdist(distmap);
distmap = distmap / max(distmap(:));
distmap1 = distmap;
distmap2 = flipdim(distmap,2);
distmap = [distmap1(:)'; distmap2(:)'];

hinc = BK_Create(wd*ht,2*wd*ht);
BK_SetNeighbors(hinc,nb);

time_inc = [];
time_new = [];

figure;

lambda = 16;
while (lambda >= 1)
    newdc = double(noise+lambda*distmap);
   
    BK_SetUnary(hinc,newdc); 
    tic; 
        e_inc = BK_Minimize(hinc);
    time_inc(end+1) = toc;
    lab = BK_GetLabeling(hinc);
    
    imagesc(reshape(lab,[wd,ht]));
    drawnow;
    
    hnew = BK_Create(wd*ht,2*wd*ht);
    BK_SetNeighbors(hnew,nb);
    BK_SetUnary(hnew,newdc); 
    tic; 
        e_new = BK_Minimize(hnew);
    time_new(end+1) = toc;
    BK_Delete(hnew);
    
    Assert(abs(e_inc - e_new) < 1e-6);
    lambda = lambda*0.9;
end

BK_Delete(hinc);
fprintf('Dynamic PASSED (%.3fsec normal, %.3fsec dynamic)\n',sum(time_new),sum(time_inc)); 

figure; plot(time_new,'-or'); hold on; plot(time_inc,'-xb');


end

