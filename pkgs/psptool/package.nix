{
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonApplication rec {
  pname = "psptool";
  version = "3.7";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-lQyTFdCizs+vK0ESGZCEqZ6SmBAyR2i/DVUpaj+uqe4=";
  };

  nativeBuildInputs = with python3Packages; [
    hatchling
    hatch-vcs
  ];
  propagatedBuildInputs = with python3Packages; [
    cryptography
    prettytable
  ];

  pythonImportsCheck = [ "psptool" ];
}
