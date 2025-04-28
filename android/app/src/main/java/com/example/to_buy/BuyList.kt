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
    val id: String,
    val name: String,
    val description: String,
    val date: Date = Date(),
    val expirationDate: Date? = null,
    val items: List<BuyItem> = listOf()
) {
    val total: Double
        get() = items.sumOf { it.getTotal() }

    val isComplete: Boolean
        get() = items.all { it.isBuy }
}
