package dev.unshell.projects

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

enum class Priority { LOW, MEDIUM, HIGH }

data class Task(val id: Int, val title: String, val priority: Priority = Priority.MEDIUM, val done: Boolean = false)

sealed interface Event {
    data class Created(val task: Task) : Event
    data class Completed(val id: Int) : Event
}

class Board(private val tasks: MutableList<Task> = mutableListOf()) {
    val open: List<Task> get() = tasks.filterNot { it.done }.sortedByDescending { it.priority }

    fun events(): Flow<Event> = flow {
        tasks.forEach { emit(Event.Created(it)) }
    }

    fun complete(id: Int): Boolean {
        val index = tasks.indexOfFirst { it.id == id }.takeIf { it >= 0 } ?: return false
        tasks[index] = tasks[index].copy(done = true)
        println("Completed ${tasks[index].title}")
        return true
    }
}
