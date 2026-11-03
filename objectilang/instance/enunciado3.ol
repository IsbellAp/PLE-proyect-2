// Snippet 3 del enunciado (Proyecto 1): varianza y override dentro de new.
// Se copia tal cual, incluido "Transform.transform" (el objeto se llama Transformer).
// Salida esperada (con el interprete):
//   Preparing specialized food for an animal...
//   y luego un error en getClass (acceso sin parentesis, seccion 5 de la guia)
object Animal
object Dog extends Animal
object Puppy extends Dog

object Food
object DogFood extends Food

object Transformer[-In, +Out]
Transform.transform = method(input: In): Out

method main {
  val animalFeeder: Transformer[Animal, DogFood] = new Transformer[Animal, DogFood] {
    override transform(animal: Animal): DogFood = {
      println("Preparing specialized food for an animal...")
      new DogFood
    }
  }

  // Contravariance (-In): Animal is a supertype of Puppy (Accepts broader input)
  // Covariance (+Out): DogFood is a subtype of Food (Returns narrower output)
  val puppyFeeder: Transformer[Puppy, Food] = animalFeeder

  val myPuppy = new Puppy
  val resultantFood: Food = puppyFeeder.transform(myPuppy)

  print("Resulting food type: ${resultantFood.getClass.getSimpleName}")
}
