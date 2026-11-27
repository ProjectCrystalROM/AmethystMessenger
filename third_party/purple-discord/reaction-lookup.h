#ifndef PURPLE_DISCORD_REACTION_LOOKUP_H
#define PURPLE_DISCORD_REACTION_LOOKUP_H

#include <json-glib/json-glib.h>
#include <time.h>

/* Returns a borrowed message object with exactly target_id, or NULL. */
JsonObject *discord_reaction_find_message(JsonNode *node, guint64 target_id);
/* Finds a message whose Snowflake timestamp in seconds matches target_time. */
JsonObject *discord_reaction_find_message_at_time(JsonNode *node,
	time_t target_time);
gboolean discord_reaction_parse_snowflake(JsonObject *object,
	const gchar *member, guint64 *value);

#endif
