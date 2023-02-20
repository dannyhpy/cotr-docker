import
  std/options,
  std/os,
  std/sequtils,
  std/strutils,
  std/strformat

when defined(dbPostgres):
  when defined(awaitDbPostgres):
    import std/net
    let socket = newSocket()
    while true:
      try:
        socket.connect(getEnv "POSTGRES_HOST", Port 5432)
        break
      except OSError:
        sleep 1_000
    socket.close()
  import std/db_postgres
  export db_postgres
  let db* = dbPostgres.open(
    getEnv "POSTGRES_HOST",
    user=getEnv "POSTGRES_USER",
    password=getEnv "POSTGRES_PASSWORD",
    database=getEnv "POSTGRES_DATABASE"
  )
  proc dbExists(): bool =
    try:
      discard db.getValue(sql"SELECT id FROM users LIMIT 1;")
      return true
    except DbError:
      return false
else:
  import std/db_sqlite
  export db_sqlite
  let dbPath = getEnv("DB_SQLITE_PATH", getTempDir() / "cotr.db")
  let dbExistsVal = fileExists dbPath
  let db* = dbSqlite.open(dbPath, "", "", "")
  proc dbExists(): bool = dbExistsVal

include "dbInitTables.nimf"
if not dbExists(): dbInitTables db

type
  SelectedRow* = object of RootObj
    cols*: seq[string]
    row*: Row

proc `[]`*(r: SelectedRow; k: string): string =
  assert k in r.cols
  return r.row[r.cols.find k]

proc contains*(r: SelectedRow, k: string): bool =
  return r[k] != ""

template `[]`*(r: SelectedRow; k: string, T: typed): untyped =
  when T is int:
    parseInt r[k]
  elif T is bool:
    r[k][0] == 't'

proc selectRow*(
  db: DbConn;
  cols: seq[string];
  tblName: string;
  where: openArray[(string, string)]
): SelectedRow =
  var sqlQuery = sql(fmt"""
    SELECT {cols.join(", ")}
    FROM {tblName}
    WHERE {join(where.mapIt(it[0] & " = ?"), " AND ")}
  """)
  result = SelectedRow(
    cols: cols,
    row: db.getRow(sqlQuery, where.mapIt it[1])
  )
