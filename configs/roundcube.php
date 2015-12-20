<?php

$config = [
  'db_dsnw'                => 'mysql://root:dev@localhost/roundcube',
  'default_host'           => '127.0.0.1',
  'log_dir'                => 'logs/',
  'temp_dir'               => 'temp/',
  'product_name'           => 'Devbox Mail',
  'des_key'                => 'IAmARandomString12345678',
  'plugins'                => [],
  'language'               => 'en_US',
  'enable_spellcheck'      => false,
  'mime_param_folding'     => 0,
  'message_cache_lifetime' =>'1d',
  'mime_types'             => __DIR__ . '/mime.types',
  'create_default_folders' => true
];
