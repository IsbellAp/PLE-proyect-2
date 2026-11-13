// errores: 14
// Regla de existencia en las definiciones de objetos: todo lo que usa una definicion debe existir.
object Animal
object Dog extends NoExiste
object Caja[+A](val item: B)
object Lista(val cabeza: Nodo, val resto: Lista)
object Doble[A, A]
object Repetido(val x: Integer, val x: String)
object Animal
object Uno extends Dos
object Dos extends Uno
object Yo extends Yo
object Numero extends Integer
object Generico[A] extends A
object MalUso(val c: Caja, val d: Animal[Integer])
object ConNombre(val nombre: String)
object Hijo(val nombre: String) extends ConNombre

method main {
  println("solo se revisan las definiciones")
}
