# diip controller

## UFT user register assignment

| Register      | Used for      |
| ------------- | ------------- |
| user_reg0     | Bit ```0```: Rising edge to start new image |
| user_reg1     | ```17 downto 0``` Window size |
| user_reg2     | ```24 downto 0``` Image width |
| user_reg3     | ```21 downto 0``` Wallis c*gvar constant |
| user_reg4     | ```5 downto 0``` Wallis c constant |
| user_reg5     | ```19 downto 0``` Wallis (1-c)*gvar constant |
| user_reg6     | ```13 downto 0``` Wallis b*gmean constant |
| user_reg7     | ```5 downto 0``` Wallis (1-b) constant |