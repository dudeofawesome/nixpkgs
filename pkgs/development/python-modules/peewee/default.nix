{ lib
, buildPythonPackage
, fetchFromGitHub
, sqlite
, cython
, apsw
, flask
, withPostgres ? false, psycopg2
, withMysql ? false, mysql-connector
}:

buildPythonPackage rec {

  pname = "peewee";
  version = "3.14.4";

  # pypi release does not provide tests
  src = fetchFromGitHub {
    owner = "coleifer";
    repo = pname;
    rev = version;
    sha256 = "0x85swpaffysc05kka0mab87cnilzw1lpacfhcx5ayabh0i2qsh6";
  };


  checkInputs = [ flask ];

  checkPhase = ''
    rm -r playhouse # avoid using the folder in the cwd
    python runtests.py
  '';

  buildInputs = [
    sqlite
    cython # compile speedups
  ];

  propagatedBuildInputs = [
    apsw # sqlite performance improvement
  ] ++ (lib.optional withPostgres psycopg2)
    ++ (lib.optional withMysql mysql-connector);

  doCheck = withPostgres;

  meta = with lib; {
    description = "a small, expressive orm";
    homepage    = "http://peewee-orm.com";
    license     = licenses.mit;
  };
}
