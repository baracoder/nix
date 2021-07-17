self: super:
{

    linuxPackagesFor = kernel:
        (super.linuxPackagesFor kernel).extend (self': super': {
        nvidiaPackages = super'.nvidiaPackages // { 
            beta = super'.nvidiaPackages.beta.overrideAttrs (a': {
                patches = [ ./nvidia-fix-linux-5.13.patch ];
    
            });
        };
    });

}