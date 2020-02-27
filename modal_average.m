function modes = modal_average(modes,exp,setup)
%if we have used peak-fitting, we need to average over the different
%estimates of natural frequency etc.

[NHam,Nmodes,NAccel] = size(modes.peak);
iFit = exp.w > setup.wMin & exp.w < setup.wMax;
H = zeros(length(exp.w),Nmodes);
for j = 1:Nmodes
    wj = zeros(NHam,NAccel);
    zj = zeros(NHam,NAccel);
    Aj = zeros(NHam,NAccel);
    for i = 1:NHam
        for k = 1:NAccel
            wj(i,k) = modes.peak(i,j,k).wr;
            zj(i,k) = modes.peak(i,j,k).zr;
            Aj(i,k) = modes.peak(i,j,k).Ar;
        end
    end
    
    iBad = ~(setup.iParallel & setup.iSameBody);
    iBad = iBad | isnan(wj) | isnan(zj) |  wj > setup.wBand(j,2) | wj < setup.wBand(j,1) | zj < 0;
    iBad = iBad & ~setup.geom.bDrivePt;
    
    wj(iBad) = NaN;
    [~,iwReject] = deleteoutliers(wj,0.5);
    iBad = iBad | (iwReject & ~setup.geom.bDrivePt);
    modes.omega(j) = mean(wj(~iBad),'omitnan');

    zj(iBad) = NaN;
    [~,izReject] = deleteoutliers(zj,0.5);
    iBad = iBad | (izReject & ~setup.geom.bDrivePt);
    modes.zeta(j) = mean(zj(~iBad),'omitnan');
    
    H(:,j) = 1./(modes.omega(j)^2 + 2*1i*modes.zeta(j)*modes.omega(j)*exp.w - exp.w.^2);
    
    if setup.options.bFitBand
        iFit = exp.w > setup.wBand(j,1) &  exp.w < setup.wBand(j,2);
        modes.A(j,:,:) = reshape(H(iFit,j)\reshape(exp.H(iFit,:,:),sum(iFit),[]),[1 NHam NAccel]);
    end
end

if ~setup.options.bFitBand
    iFit = exp.w > setup.wMin & exp.w < setup.wMax;
    modes.A = reshape(H(iFit,:) \ reshape(exp.H(iFit,:,:),sum(iFit),[]),[Nmodes NHam NAccel]);

end