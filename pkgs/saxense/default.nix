{
stdenv,
cmake,
fetchGitHub

}:

stdenv.mkDerivation {
  pname = "SAxense";
  version = "7aa7ea2";
  src = fetchGitHub {
    owner = "anton-matosov";
    repo = "SAxense";
    ref = "master";
    rev = "7aa7ea2";
  };

  nativeBuildInputs = [cmake];


}
