package main

import "gorm.io/gorm"

// seed отключён: каждый магазин создаёт своё меню через API.
func seed(_ *gorm.DB) {}
