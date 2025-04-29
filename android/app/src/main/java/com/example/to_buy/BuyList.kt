package com.example.to_buy

import java.util.*

data class BuyItem(
    val name: String,
    val price: Double,
    val quantity: Double,
    val date: Date,
    val isBuy: Boolean
) {
    fun getTotal(): Double {
        return price * quantity
    }
}

data class BuyList(
    val name: String,
    val description: String
) {
   
}
