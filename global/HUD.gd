extends Node


signal cast_ability_effect(number: int, time: float)
signal set_ability_cooldown(number: int, time: float)
signal activate_claws()
signal deplete_claws(amount: int)
signal deactivate_claws()
signal activate_block()
signal deplete_block(amount: int)
signal deactivate_block()
signal activate_ult(amount: int)
signal deactivate_ult()
signal deplete_shard()
