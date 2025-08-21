-- Grant execute permissions on message helper functions to authenticated users
GRANT EXECUTE ON FUNCTION public.get_conversation_messages(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_messages_as_read(UUID, UUID) TO authenticated;


