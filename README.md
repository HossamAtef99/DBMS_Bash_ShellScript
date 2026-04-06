# Bash DBMS Script 🗄️

A **command-line Database Management System** written in Bash.  
It allows you to create databases, tables, and perform basic operations like **insert, select, update, delete**, all with simple file-based storage.

---

## Features ✅

- Create, list, connect, and drop databases
- Create, list, drop tables inside databases
- Insert, select, update, and delete records
- Primary key enforcement
- Simple file-based storage using `:` delimiter
- Fully interactive command-line menus

---

## How it Works 🔧

- Each **database** is a folder.
- Each **table** is a file inside its database folder.
- Table metadata (columns and primary key) is stored in the first line of the file:

## Requirements ⚙️
- Bash (Linux / macOS)
- No external dependencies

