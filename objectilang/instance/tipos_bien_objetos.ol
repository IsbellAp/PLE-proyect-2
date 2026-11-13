// errores: 0
// Objetos: herencia, subtipos, genericos con varianza, campos, metodos y override.
// Salida esperada (Generador), una por linea:
//   Guau, soy Rex de raza pastor / Hola, Guau, soy Rex de raza pastor / pastor / Soy Rex / Dog / 10 / uno /
//   Preparing food for an animal / DogFood / Miau / DogFood
object Animal
object Dog(val nombre: String, val raza: String) extends Animal
object Puppy extends Dog
object Food
object DogFood extends Food

object Caja[+A](val item: A)
object Par[A, B](val primero: A, val segundo: B)
object Transformer[-In, +Out]
object Etiquetada[+T](val etiqueta: String) extends Caja[T]

Animal.hablar = method(): String { "..." }
Dog.hablar = method(): String { "Guau, soy $nombre de raza ${raza}" }
Animal.saludar = method(otro: Animal): String { "Hola, ${otro.hablar()}" }
Dog.presentar = method(): String { "Soy $nombre" }
Caja.sacar = method(): A { item }
Par.cambiar = method(): Par[B, A] { new Par(segundo, primero) }
Transformer.transform = method(input: In): Out

method main {
  val d: Dog = new Dog("Rex", "pastor")
  val a: Animal = d
  val p: Animal = new Puppy
  println(a.hablar())
  println(p.saludar(d))
  println(d.raza)
  println(d.presentar())

  val cajaPerro: Caja[Dog] = new Caja(d)
  val cajaAnimal: Caja[Animal] = cajaPerro
  val sacado: Animal = cajaAnimal.sacar()
  val otra: Caja[Animal] = new Etiquetada[Dog]("perros")
  val explicita: Caja[Integer] = new Caja[Integer](5)
  val total: Integer = explicita.sacar() + explicita.item
  println(sacado)
  println(total)

  val par: Par[Integer, String] = new Par(1, "uno")
  val volteado: Par[String, Integer] = par.cambiar()
  val texto: String = volteado.primero
  println(texto)

  val animalFeeder: Transformer[Animal, DogFood] = new Transformer[Animal, DogFood] {
    override transform(animal: Animal): DogFood = {
      println("Preparing food for an animal")
      new DogFood
    }
  }
  val puppyFeeder: Transformer[Puppy, Food] = animalFeeder
  val comida: Food = puppyFeeder.transform(new Puppy)
  println(comida)

  val gato = new Animal { override hablar(): String = { "Miau" } }
  println(gato.hablar())
  println(comida.getClass.getSimpleName)
}
