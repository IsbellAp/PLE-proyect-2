// Snippet 4 del enunciado (Proyecto 1): if-then-else y for.
// El snippet son dos lineas sueltas; se agrega un main con a, b y ratings.
// Salida esperada (con el interprete):
//   7
//   Movie: ana, Rating: 5
//   Movie: bob, Rating: 3
method main {
  val a = 3
  val b = 7
  val ratings = (("ana", 5), ("bob", 3))
  val max = if a > b then a else b
  println(max)
  for ((name, rating) <- ratings) println("Movie: $name, Rating: $rating")
}
