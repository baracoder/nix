{
  python3Packages,
  fetchFromGitHub

}:

python3Packages.buildPythonApplication {
  pname = "pywincontrols";
  version = "unstable";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "pelrun";
    repo = "pyWinControls";
    rev = "main";
    hash = "sha256-ySqogpUKVNjACCT+P6mrXxTD+4mBXACDb+48tdfls8U=";
  };

  preBuild = ''
  sed -i 's/K406/K123/' gpdconfig/wincontrols/hardware.py
  '';

  nativeBuildInputs = [ python3Packages.setuptools ];
  propagatedBuildInputs = with python3Packages; [
    hid
  ];

}