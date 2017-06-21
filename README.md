# MultiGameTimer-iOS

## Bluetooth Service schema
* **Service**: GameService, uuid varies with 3 digit generated game code
    * **Characteristic**: StartPlay, Central writes to this to alert peripherals the game has started
    * **Characteristic**: IsPlayerTurn, Central writes to this when it is that peripheral's turn, then subscribes to notifications from it. Peripheral writes to it when it has finished it's turn.
    
