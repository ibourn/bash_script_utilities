# aoc_rs.sh

This is a bash script to prepare a new **[Advent of Code](https://adventofcode.com/) project in rust**.

It will create :

- a new folder with the given name,
- a new rust project inside with :
  - a prepared README file,
  - a configured cargo.toml,
  - src/lib.rs which can be used for the reusable code.
- 25 daily projects in src/bin with the 2 parts for each day :
  - 2 test.txt files to enter your test inputs,
  - 2 input.txt files to enter the challenge inputs,
  - part1.rs and part2.rs for your logic,
  - a README file for the daily challenge.

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version`
- [rust](https://www.rust-lang.org/learn/get-started)
  - You'll know you did it right if you can run `cargo --version`

## Usage

For your project use the **snake case** naming convention (i.e. words in lowercase separated by underscores).

#### Get the script :

- Clone the repository and navigate to the project directory.

- Or copy the script where you want to create your project.

#### Run it in your terminal :

1. `chmod +x aoc_rs.sh` to make it executable.
2. `./aoc_rs.sh <folder_name> <AOC_year>` to run it (ex: ./aoc_rs.sh aoc_2022 2022).

#### Then, in your project, run your tests or solutions with :

- `cargo test --bin dayXX_partY`
- `cargo run --bin dayXX_partY`

XX : the day of the challenge [01-25] and Y : the part of the day [1-2]

example : `cargo run --bin day01_part1`

### _Feel free to explore and suggest improvements!_
