import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/int
import gleam/map.{Map}

pub type Name {
  IronOre
  IronInglot
  CopperOre
  CopperInglot
  Magnet
  Gear
  MagneticCoil
  ElectricMotor
  ElectroMagneticTurbine
}

type Recipe {
  Recipe(name: Name, time: Float, makes: Float, needs: List(#(Float, Name)))
}

const recipes = [
  Recipe(name: CopperOre, makes: 1.0, time: 1.0, needs: []),
  Recipe(name: CopperInglot, makes: 1.0, time: 1.0, needs: [#(1.0, CopperOre)]),
  Recipe(name: IronOre, makes: 1.0, time: 1.0, needs: []),
  Recipe(name: IronInglot, makes: 1.0, time: 1.0, needs: [#(1.0, IronOre)]),
  Recipe(name: Magnet, makes: 1.0, time: 1.5, needs: [#(1.0, IronOre)]),
  Recipe(name: Gear, makes: 1.0, time: 1.0, needs: [#(1.0, IronInglot)]),
  Recipe(
    name: MagneticCoil,
    makes: 1.0,
    time: 1.0,
    needs: [#(2.0, Magnet), #(1.0, CopperInglot)],
  ),
  Recipe(
    name: ElectricMotor,
    makes: 1.0,
    time: 2.0,
    needs: [#(2.0, IronInglot), #(1.0, Gear), #(1.0, MagneticCoil)],
  ),
  Recipe(
    name: ElectroMagneticTurbine,
    makes: 1.0,
    time: 2.0,
    needs: [#(2.0, ElectricMotor), #(2.0, MagneticCoil)],
  ),
]

pub fn main() {
  // io.println("Hello from recipes!")

  let indexed =
    indexed_recipes()
    |> io.debug

  // let needs = make(indexed, Magnet, 1.0)
  let needs = make(indexed, ElectroMagneticTurbine, 1.0)

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

fn normalize_recipe_time(recipe: Recipe) -> Recipe {
  let multiplier = 1.0 /. recipe.time

  let next_needs =
    recipe.needs
    |> list.map(fn(need) {
      let #(qty, name) = need
      #(qty *. multiplier, name)
    })

  Recipe(..recipe, makes: multiplier, time: 1.0, needs: next_needs)
}

type Indexed =
  Map(Name, Recipe)

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
