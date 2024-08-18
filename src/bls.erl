-module(bls).
-export([
    generate_secret_key/0,
    secret_key_from_bytes/1,
    secret_key_to_bytes/1,
    derive_public_key/1,
    public_key_from_bytes/1,
    public_key_to_bytes/1,
    create_proof_of_knowledge/2,
    signature_to_bytes/1
]).
-nifs([
    generate_secret_key/0,
    secret_key_from_bytes/1,
    secret_key_to_bytes/1,
    derive_public_key/1,
    public_key_from_bytes/1,
    public_key_to_bytes/1,
    create_proof_of_knowledge/2,
    signature_to_bytes/1
]).
-on_load(init/0).

init() ->
    ok = erlang:load_nif("priv/libbls", 0).

generate_secret_key() ->
    exit(nif_library_not_loaded).

secret_key_from_bytes(bytes) ->
    exit(nif_library_not_loaded).

secret_key_to_bytes(secret_key) ->
    exit(nif_library_not_loaded).

derive_public_key(secret_key) ->
    exit(nif_library_not_loaded).

public_key_from_bytes(bytes) ->
    exit(nif_library_not_loaded).

public_key_to_bytes(public_key) ->
    exit(nif_library_not_loaded).

create_proof_of_knowledge(secret_key, public_key) ->
    exit(nif_library_not_loaded).

signature_to_bytes(signature) ->
    exit(nif_library_not_loaded).
