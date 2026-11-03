// for sobre una tupla de tuplas, con desestructuracion e interpolacion.
// Salida esperada:
//   Movie: ana, Rating: 5
//   Movie: bob, Rating: 3
method main {
  for ((n, r) <- (("ana", 5), ("bob", 3))) println("Movie: $n, Rating: $r")
}
