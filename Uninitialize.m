function Uninitialize()

global System;

if(~isempty(System))
    if(~isempty(System.ActiveProject))
        System.ActiveProject.LogicalLinks.RemoveAll;
        System.DeselectProject;
    end;
    delete(System);
end;
