// errores: 3 (el enunciado escribe Transform.transform y el objeto se llama Transformer)
// Snippet 3 del enunciado (Proyecto 1): varianza y override dentro de new.
// Se copia tal cual, incluido "Transform.transform" (el objeto se llama Transformer).
// Salida esperada (con el generador de Java):
//   Preparing specialized food for an animal...
//   Resulting food type: DogFood   (getClass y getSimpleName se generan como metodos de Java)
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
