import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/int
import gleam/map.{Map}

pub type Name {
  CarbonNanotube
  Coal
  CopperInglot
  CopperOre
  Diamond
  ElectricMotor
  ElectroMagneticTurbine
  EnergeticGraphite
  FireIce
  Gear
  Graphene
  IronInglot
  IronOre
  Magnet
  MagneticCoil
  ProliferatorMark1
  ProliferatorMark2
  ProliferatorMark3
  TitaniumInglot
  TitaniumOre
}

type Recipe {
  Recipe(name: Name, time: Float, makes: Int, needs: List(#(Int, Name)))
}

type NormalisedRecipe {
  NormalisedRecipe(
    name: Name,
    time: Float,
    makes: Float,
    needs: List(#(Float, Name)),
  )
}

const recipes = [
  // Raw
  Recipe(name: Coal, time: 1.0, makes: 1, needs: []),
  Recipe(name: CopperOre, time: 1.0, makes: 1, needs: []),
  Recipe(name: IronOre, time: 1.0, makes: 1, needs: []),
  Recipe(name: FireIce, time: 1.0, makes: 1, needs: []),
  Recipe(name: TitaniumOre, time: 1.0, makes: 1, needs: []),
  // Inglots
  Recipe(name: CopperInglot, time: 1.0, makes: 1, needs: [#(1, CopperOre)]),
  Recipe(name: IronInglot, time: 1.0, makes: 1, needs: [#(1, IronOre)]),
  Recipe(name: TitaniumInglot, time: 2.0, makes: 1, needs: [#(2, TitaniumOre)]),
  //
  Recipe(name: Magnet, time: 1.5, makes: 1, needs: [#(1, IronOre)]),
  Recipe(name: Gear, time: 1.0, makes: 1, needs: [#(1, IronInglot)]),
  Recipe(
    name: MagneticCoil,
    time: 1.0,
    makes: 1,
    needs: [#(2, Magnet), #(1, CopperInglot)],
  ),
  Recipe(
    name: ElectricMotor,
    time: 2.0,
    makes: 1,
    needs: [#(2, IronInglot), #(1, Gear), #(1, MagneticCoil)],
  ),
  Recipe(
    name: ElectroMagneticTurbine,
    time: 2.0,
    makes: 1,
    needs: [#(2, ElectricMotor), #(2, MagneticCoil)],
  ),
  Recipe(name: EnergeticGraphite, time: 2.0, makes: 1, needs: [#(2, Coal)]),
  Recipe(name: Diamond, time: 2.0, makes: 1, needs: [#(1, EnergeticGraphite)]),
  Recipe(name: Graphene, time: 2.0, makes: 2, needs: [#(2, FireIce)]),
  Recipe(
    name: CarbonNanotube,
    time: 4.0,
    makes: 2,
    needs: [#(3, Graphene), #(1, TitaniumInglot)],
  ),
  Recipe(name: ProliferatorMark1, time: 0.5, makes: 1, needs: [#(1, Coal)]),
  Recipe(
    name: ProliferatorMark2,
    time: 1.0,
    makes: 1,
    needs: [#(2, ProliferatorMark1), #(1, Diamond)],
  ),
  Recipe(
    name: ProliferatorMark3,
    time: 2.0,
    makes: 1,
    needs: [#(2, ProliferatorMark2), #(1, CarbonNanotube)],
  ),
]

pub fn main() {
  // io.println("Hello from recipes!")

  let indexed = indexed_recipes()
  // |> io.debug

  // let needs = make(indexed, Magnet, 1.0)
  // let needs = make(indexed, ElectroMagneticTurbine, 1.0)
  let needs = make(indexed, ProliferatorMark3, 2.0)

  let grouped = list.fold(over: needs, from: map.new(), with: fold_counts)

  grouped
  |> map.to_list
  |> list.map(io.debug)
}

fn fold_counts(acc: Map(Name, Float), need: #(Name, Float)) -> Map(Name, Float) {
  let #(need_name, need_qty) = need

  map.update(
    acc,
    need_name,
    fn(current: Option(Float)) {
      case current {
        Some(qty) -> qty +. need_qty
        None -> need_qty
      }
    },
  )
}

fn indexed_recipes() {
  recipes
  // First we want to normalize the time for all recipes
  |> list.map(normalize_recipe_time)
  |> list.map(fn(recipe) { #(recipe.name, recipe) })
  |> map.from_list
}

fn normalize_recipe_time(recipe: Recipe) -> NormalisedRecipe {
  let multiplier = 1.0 /. recipe.time

  let next_needs =
    recipe.needs
    |> list.map(fn(need) {
      let #(qty, name) = need
      #(int.to_float(qty) *. multiplier, name)
    })

  NormalisedRecipe(
    name: recipe.name,
    makes: multiplier *. int.to_float(recipe.makes),
    time: 1.0,
    needs: next_needs,
  )
}

type Indexed =
  Map(Name, NormalisedRecipe)

fn make(indexed: Indexed, name: Name, qty: Float) -> List(#(Name, Float)) {
  let recipe_result = map.get(indexed, name)

  case recipe_result {
    Ok(recipe) -> {
      let materials =
        recipe.needs
        |> list.flat_map(fn(need) {
          let #(need_qty, need_name) = need
          let total_needed = need_qty *. qty /. recipe.makes

          make(indexed, need_name, total_needed)
        })

      [#(name, qty), ..materials]
    }

    Error(_) -> {
      io.debug("Failed to find recipe")
      io.debug(name)
      []
    }
  }
}
