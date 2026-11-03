// override de un metodo ya definido, dentro de new.
// Salida esperada: sonido sobrescrito
object Animal
Animal.hablar = method(): String { "sonido original" }

method main {
  val a = new Animal { override hablar(): String = { "sonido sobrescrito" } }
  println(a.hablar())
}
