# Copyright 2023-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Autogenerated by pycargoebuild 0.13.2

EAPI=8

CRATES="
	addr2line@0.21.0
	adler@1.0.2
	aes@0.8.4
	ahash@0.7.8
	ahash@0.8.10
	aho-corasick@1.1.2
	alloc-no-stdlib@2.0.4
	alloc-stdlib@0.2.2
	android-tzdata@0.1.1
	android_system_properties@0.1.5
	anyhow@1.0.80
	arc-swap@1.6.0
	async-broadcast@0.5.1
	async-channel@1.9.0
	async-channel@2.2.0
	async-executor@1.8.0
	async-fs@1.6.0
	async-io@1.13.0
	async-io@2.3.1
	async-lock@2.8.0
	async-lock@3.3.0
	async-net@1.8.0
	async-process@1.8.1
	async-recursion@1.0.5
	async-signal@0.2.5
	async-task@4.7.0
	async-trait@0.1.77
	atk-sys@0.15.1
	atk@0.15.1
	atomic-waker@1.1.2
	auto-launch@0.5.0
	autocfg@1.1.0
	backon@0.4.2
	backtrace@0.3.69
	base64@0.13.1
	base64@0.21.7
	base64@0.22.0
	base64ct@1.6.0
	bindgen@0.69.4
	bit_field@0.10.2
	bitflags@1.3.2
	bitflags@2.4.2
	block-buffer@0.10.4
	block-buffer@0.9.0
	block@0.1.6
	blocking@1.5.1
	brotli-decompressor@2.5.1
	brotli@3.4.0
	bstr@1.9.1
	bumpalo@3.15.3
	bytemuck@1.14.3
	byteorder@1.5.0
	bytes@1.5.0
	bzip2-sys@0.1.11+1.0.8
	bzip2@0.4.4
	cairo-rs@0.15.12
	cairo-sys-rs@0.15.1
	cargo_toml@0.15.3
	cc@1.0.88
	cesu8@1.1.0
	cexpr@0.6.0
	cfb@0.7.3
	cfg-expr@0.15.7
	cfg-expr@0.9.1
	cfg-if@1.0.0
	chrono@0.4.34
	cipher@0.4.4
	clang-sys@1.7.0
	cocoa-foundation@0.1.2
	cocoa@0.24.1
	cocoa@0.25.0
	color_quant@1.1.0
	combine@4.6.6
	concat-idents@1.1.5
	concurrent-queue@2.4.0
	constant_time_eq@0.1.5
	convert_case@0.4.0
	core-foundation-sys@0.8.6
	core-foundation@0.9.4
	core-graphics-types@0.1.3
	core-graphics@0.22.3
	core-graphics@0.23.1
	cpufeatures@0.2.12
	crc32fast@1.4.0
	cron_clock@0.8.0
	crossbeam-channel@0.5.12
	crossbeam-deque@0.8.5
	crossbeam-epoch@0.9.18
	crossbeam-utils@0.8.19
	crunchy@0.2.2
	crypto-common@0.1.6
	cssparser-macros@0.6.1
	cssparser@0.27.2
	ctor@0.2.7
	ctrlc@3.4.2
	cursor-icon@1.1.0
	darling@0.20.8
	darling_core@0.20.8
	darling_macro@0.20.8
	dashmap@4.0.2
	dashmap@5.5.3
	data-encoding@2.5.0
	deelevate@0.2.0
	delay_timer@0.11.5
	deranged@0.3.11
	derivative@2.2.0
	derive_more@0.99.17
	digest@0.10.7
	digest@0.9.0
	dirs-next@2.0.0
	dirs-sys-next@0.1.2
	dirs-sys@0.3.7
	dirs-sys@0.4.1
	dirs@4.0.0
	dirs@5.0.1
	dispatch@0.2.0
	dlib@0.5.2
	downcast-rs@1.2.0
	dtoa-short@0.3.4
	dtoa@1.0.9
	dunce@1.0.4
	dyn-clone@1.0.17
	either@1.10.0
	embed-resource@2.4.1
	embed_plist@1.2.2
	encoding_rs@0.8.33
	enumflags2@0.7.9
	enumflags2_derive@0.7.9
	equivalent@1.0.1
	errno@0.3.8
	event-listener-strategy@0.4.0
	event-listener-strategy@0.5.0
	event-listener@2.5.3
	event-listener@3.1.0
	event-listener@4.0.3
	event-listener@5.2.0
	exr@1.72.0
	fast_image_resize@3.0.4
	fastrand@1.9.0
	fastrand@2.0.1
	fdeflate@0.3.4
	field-offset@0.3.6
	filedescriptor@0.8.2
	filetime@0.2.23
	fixedbitset@0.4.2
	flate2@1.0.28
	float-cmp@0.9.0
	flume@0.11.0
	fnv@1.0.7
	foreign-types-macros@0.2.3
	foreign-types-shared@0.1.1
	foreign-types-shared@0.3.1
	foreign-types@0.3.2
	foreign-types@0.5.0
	form_urlencoded@1.2.1
	futf@0.1.5
	futures-channel@0.3.30
	futures-core@0.3.30
	futures-executor@0.3.30
	futures-io@0.3.30
	futures-lite@1.13.0
	futures-lite@2.2.0
	futures-macro@0.3.30
	futures-sink@0.3.30
	futures-task@0.3.30
	futures-util@0.3.30
	futures@0.3.30
	fxhash@0.2.1
	gdk-pixbuf-sys@0.15.10
	gdk-pixbuf@0.15.11
	gdk-sys@0.15.1
	gdk@0.15.4
	gdkwayland-sys@0.15.3
	gdkx11-sys@0.15.1
	generator@0.7.6
	generic-array@0.14.7
	getrandom@0.1.16
	getrandom@0.2.12
	gif@0.13.1
	gimli@0.28.1
	gio-sys@0.15.10
	gio@0.15.12
	glib-macros@0.15.13
	glib-sys@0.15.10
	glib@0.15.12
	glob@0.3.1
	globset@0.4.14
	globwalk@0.8.1
	gobject-sys@0.15.10
	gtk-sys@0.15.3
	gtk3-macros@0.15.6
	gtk@0.15.5
	h2@0.3.24
	half@2.4.0
	halfbrown@0.2.4
	handlebars@3.5.5
	hashbrown@0.12.3
	hashbrown@0.13.2
	hashbrown@0.14.3
	headers-core@0.2.0
	headers@0.3.9
	heck@0.3.3
	heck@0.4.1
	hermit-abi@0.3.9
	hex@0.4.3
	hmac@0.12.1
	home@0.5.9
	html5ever@0.26.0
	http-body@0.4.6
	http-range@0.1.5
	http@0.2.11
	httparse@1.8.0
	httpdate@1.0.3
	hyper-rustls@0.24.2
	hyper-tls@0.5.0
	hyper@0.14.28
	iana-time-zone-haiku@0.1.2
	iana-time-zone@0.1.60
	ico@0.3.0
	ident_case@1.0.1
	idna@0.5.0
	ignore@0.4.22
	image@0.24.9
	indexmap@1.9.3
	indexmap@2.2.5
	infer@0.13.0
	infer@0.9.0
	inout@0.1.3
	instant@0.1.12
	interfaces@0.0.9
	interprocess@1.2.1
	io-lifetimes@1.0.11
	ipnet@2.9.0
	iptools@0.2.5
	is-docker@0.2.0
	is-wsl@0.4.0
	itertools@0.12.1
	itoa@0.4.8
	itoa@1.0.10
	javascriptcore-rs-sys@0.4.0
	javascriptcore-rs@0.16.0
	jni-sys@0.3.0
	jni@0.20.0
	jpeg-decoder@0.3.1
	js-sys@0.3.68
	json-patch@1.2.0
	kuchikiki@0.8.2
	lazy_static@1.4.0
	lazycell@1.3.0
	lebe@0.5.2
	lexical-core@0.8.5
	lexical-parse-float@0.8.5
	lexical-parse-integer@0.8.6
	lexical-util@0.8.5
	lexical-write-float@0.8.5
	lexical-write-integer@0.8.5
	libappindicator-sys@0.7.3
	libappindicator@0.7.1
	libc@0.2.153
	libloading@0.7.4
	libloading@0.8.2
	libredox@0.0.1
	librocksdb-sys@0.16.0+8.10.0
	libz-sys@1.1.15
	line-wrap@0.1.1
	linked-hash-map@0.5.6
	linux-raw-sys@0.3.8
	linux-raw-sys@0.4.13
	lock_api@0.4.11
	log@0.4.21
	loom@0.5.6
	lru@0.7.8
	lz4-sys@1.9.4
	mac-notification-sys@0.6.1
	mac@0.1.1
	malloc_buf@0.0.6
	markup5ever@0.11.0
	matchers@0.1.0
	matches@0.1.10
	memchr@2.7.1
	memmap2@0.9.4
	memmem@0.1.1
	memoffset@0.6.5
	memoffset@0.7.1
	memoffset@0.9.0
	mime@0.3.17
	mime_guess@2.0.4
	minimal-lexical@0.2.1
	minisign-verify@0.2.1
	miniz_oxide@0.7.2
	mio@0.8.11
	multer@2.1.0
	nanoid@0.4.0
	native-tls@0.2.11
	ndk-context@0.1.1
	ndk-sys@0.3.0
	ndk@0.6.0
	new_debug_unreachable@1.0.4
	nix@0.23.2
	nix@0.26.4
	nix@0.27.1
	nodrop@0.1.14
	nom@5.1.3
	nom@7.1.3
	normpath@1.2.0
	notify-rust@4.10.0
	ntapi@0.4.1
	nu-ansi-term@0.46.0
	num-conv@0.1.0
	num-derive@0.3.3
	num-traits@0.2.18
	num_cpus@1.16.0
	num_enum@0.5.11
	num_enum_derive@0.5.11
	objc-foundation@0.1.1
	objc-sys@0.3.2
	objc2-encode@4.0.0
	objc2@0.5.0
	objc@0.2.7
	objc_exception@0.1.2
	objc_id@0.1.1
	object@0.32.2
	once_cell@1.19.0
	opaque-debug@0.3.1
	open@3.2.0
	open@5.1.1
	openssl-macros@0.1.1
	openssl-probe@0.1.5
	openssl-src@300.2.3+3.2.1
	openssl-sys@0.9.101
	openssl@0.10.64
	option-ext@0.2.0
	ordered-float@2.10.1
	ordered-stream@0.2.0
	os_info@3.7.0
	os_pipe@1.1.5
	overload@0.1.1
	pango-sys@0.15.10
	pango@0.15.10
	parking@2.2.0
	parking_lot@0.12.1
	parking_lot_core@0.9.9
	password-hash@0.4.2
	pathdiff@0.2.1
	pathsearch@0.2.0
	pbkdf2@0.11.0
	percent-encoding@2.3.1
	pest@2.7.8
	pest_derive@2.7.8
	pest_generator@2.7.8
	pest_meta@2.7.8
	petgraph@0.6.4
	phf@0.10.1
	phf@0.11.2
	phf@0.8.0
	phf_codegen@0.10.0
	phf_codegen@0.11.2
	phf_codegen@0.8.0
	phf_generator@0.10.0
	phf_generator@0.11.2
	phf_generator@0.8.0
	phf_macros@0.11.2
	phf_macros@0.8.0
	phf_shared@0.10.0
	phf_shared@0.11.2
	phf_shared@0.8.0
	pin-project-internal@1.1.4
	pin-project-lite@0.2.13
	pin-project@1.1.4
	pin-utils@0.1.0
	piper@0.2.1
	pkg-config@0.3.30
	plist@1.6.0
	png@0.17.13
	polling@2.8.0
	polling@3.5.0
	port_scanner@0.1.5
	powerfmt@0.2.0
	ppv-lite86@0.2.17
	precomputed-hash@0.1.1
	proc-macro-crate@1.3.1
	proc-macro-error-attr@1.0.4
	proc-macro-error@1.0.4
	proc-macro-hack@0.5.20+deprecated
	proc-macro2@1.0.78
	qoi@0.4.1
	quick-error@2.0.1
	quick-xml@0.30.0
	quick-xml@0.31.0
	quote@1.0.35
	rand@0.7.3
	rand@0.8.5
	rand_chacha@0.2.2
	rand_chacha@0.3.1
	rand_core@0.5.1
	rand_core@0.6.4
	rand_hc@0.2.0
	rand_pcg@0.2.1
	raw-window-handle@0.5.2
	raw-window-handle@0.6.0
	rayon-core@1.12.1
	rayon@1.9.0
	redox_syscall@0.4.1
	redox_users@0.4.4
	ref-cast-impl@1.0.22
	ref-cast@1.0.22
	regex-automata@0.1.10
	regex-automata@0.4.5
	regex-syntax@0.6.29
	regex-syntax@0.8.2
	regex@1.10.3
	reqwest@0.11.24
	rfd@0.10.0
	ring@0.17.8
	rocksdb@0.22.0
	rquickjs-core@0.5.1
	rquickjs-sys@0.5.1
	rquickjs@0.5.1
	rs-snowflake@0.6.0
	runas@1.2.0
	rust-i18n-macro@3.0.0
	rust-i18n-support@3.0.1
	rust-i18n@3.0.1
	rustc-demangle@0.1.23
	rustc-hash@1.1.0
	rustc_version@0.2.3
	rustc_version@0.4.0
	rustix@0.37.27
	rustix@0.38.31
	rustls-pemfile@1.0.4
	rustls-webpki@0.101.7
	rustls@0.21.10
	rustversion@1.0.14
	ryu@1.0.17
	safemem@0.3.3
	same-file@1.0.6
	schannel@0.1.23
	scoped-tls@1.0.1
	scopeguard@1.2.0
	sct@0.7.1
	security-framework-sys@2.9.1
	security-framework@2.9.2
	selectors@0.22.0
	semver-parser@0.10.2
	semver-parser@0.7.0
	semver@0.11.0
	semver@0.9.0
	semver@1.0.22
	serde@1.0.197
	serde_derive@1.0.197
	serde_json@1.0.114
	serde_repr@0.1.18
	serde_spanned@0.6.5
	serde_urlencoded@0.7.1
	serde_with@3.6.1
	serde_with_macros@3.6.1
	serde_yaml@0.8.26
	serde_yaml@0.9.32
	serialize-to-javascript-impl@0.1.1
	serialize-to-javascript@0.1.1
	servo_arc@0.1.1
	sha1@0.10.6
	sha2@0.10.8
	sha2@0.9.9
	sharded-slab@0.1.7
	shared_child@1.0.0
	shared_library@0.1.9
	shlex@1.3.0
	signal-hook-registry@1.4.1
	signal-hook@0.1.17
	simd-adler32@0.3.7
	simd-json@0.13.8
	simdutf8@0.1.4
	single-instance@0.3.3
	siphasher@0.3.11
	slab@0.4.9
	smallvec@1.13.1
	smithay-client-toolkit@0.18.1
	smol@1.3.0
	socket2@0.4.10
	socket2@0.5.6
	soup2-sys@0.2.0
	soup2@0.2.1
	spin@0.9.8
	stable_deref_trait@1.2.0
	state@0.5.3
	static_assertions@1.1.0
	string_cache@0.8.7
	string_cache_codegen@0.5.2
	strsim@0.10.0
	subtle@2.5.0
	syn@1.0.109
	syn@2.0.52
	sync_wrapper@0.1.2
	sys-locale@0.2.4
	sysinfo@0.30.6
	system-configuration-sys@0.5.0
	system-configuration@0.5.1
	system-deps@5.0.0
	system-deps@6.2.0
	tao-macros@0.1.2
	tao@0.16.7
	tar@0.4.40
	target-lexicon@0.12.14
	tauri-build@1.5.1
	tauri-codegen@1.4.2
	tauri-macros@1.4.3
	tauri-runtime-wry@0.14.5
	tauri-runtime@0.14.2
	tauri-utils@1.5.3
	tauri-winres@0.1.1
	tauri-winrt-notification@0.1.3
	tauri@1.6.1
	tempfile@3.10.1
	tendril@0.4.3
	terminfo@0.7.5
	termios@0.3.3
	termwiz@0.15.0
	thin-slice@0.1.1
	thiserror-impl@1.0.57
	thiserror@1.0.57
	thread-id@4.2.1
	thread_local@1.1.8
	tiff@0.9.1
	time-core@0.1.2
	time-macros@0.2.17
	time@0.3.34
	tinyvec@1.6.0
	tinyvec_macros@0.1.1
	to_method@1.1.0
	tokio-macros@2.2.0
	tokio-native-tls@0.3.1
	tokio-rustls@0.24.1
	tokio-stream@0.1.14
	tokio-tungstenite@0.20.1
	tokio-util@0.7.10
	tokio@1.36.0
	toml@0.5.11
	toml@0.7.8
	toml@0.8.10
	toml_datetime@0.6.5
	toml_edit@0.19.15
	toml_edit@0.22.6
	tower-service@0.3.2
	tracing-appender@0.2.3
	tracing-attributes@0.1.27
	tracing-core@0.1.32
	tracing-error@0.2.0
	tracing-futures@0.2.5
	tracing-log@0.2.0
	tracing-serde@0.1.3
	tracing-subscriber@0.3.18
	tracing@0.1.40
	treediff@4.0.3
	triomphe@0.1.11
	try-lock@0.2.5
	tungstenite@0.20.1
	typenum@1.17.0
	ucd-trie@0.1.6
	uds_windows@1.1.0
	unicase@2.7.0
	unicode-bidi@0.3.15
	unicode-ident@1.0.12
	unicode-normalization@0.1.23
	unicode-segmentation@1.11.0
	unsafe-libyaml@0.2.10
	untrusted@0.9.0
	url@2.5.0
	utf-8@0.7.6
	utf8parse@0.2.1
	uuid@1.7.0
	valuable@0.1.0
	value-trait@0.8.1
	vcpkg@0.2.15
	version-compare@0.0.11
	version-compare@0.1.1
	version_check@0.9.4
	vswhom-sys@0.1.2
	vswhom@0.1.0
	vtparse@0.6.2
	waker-fn@1.1.1
	walkdir@2.5.0
	want@0.3.1
	warp@0.3.6
	wasi@0.11.0+wasi-snapshot-preview1
	wasi@0.9.0+wasi-snapshot-preview1
	wasm-bindgen-backend@0.2.91
	wasm-bindgen-futures@0.4.41
	wasm-bindgen-macro-support@0.2.91
	wasm-bindgen-macro@0.2.91
	wasm-bindgen-shared@0.2.91
	wasm-bindgen@0.2.91
	wasm-streams@0.4.0
	wayland-backend@0.3.3
	wayland-client@0.31.2
	wayland-csd-frame@0.3.0
	wayland-cursor@0.31.1
	wayland-protocols-wlr@0.2.0
	wayland-protocols@0.31.2
	wayland-scanner@0.31.1
	wayland-sys@0.31.1
	web-sys@0.3.68
	webkit2gtk-sys@0.18.0
	webkit2gtk@0.18.2
	webpki-roots@0.25.4
	webview2-com-macros@0.6.0
	webview2-com-sys@0.19.0
	webview2-com@0.19.1
	weezl@0.1.8
	which@4.4.2
	which@6.0.0
	widestring@0.4.3
	widestring@1.0.2
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-util@0.1.6
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	window-shadows@0.2.2
	window-vibrancy@0.5.0
	windows-bindgen@0.39.0
	windows-core@0.51.1
	windows-core@0.52.0
	windows-core@0.53.0
	windows-core@0.54.0
	windows-implement@0.39.0
	windows-metadata@0.39.0
	windows-result@0.1.0
	windows-sys@0.42.0
	windows-sys@0.45.0
	windows-sys@0.48.0
	windows-sys@0.52.0
	windows-targets@0.42.2
	windows-targets@0.48.5
	windows-targets@0.52.4
	windows-tokens@0.39.0
	windows-version@0.1.0
	windows@0.37.0
	windows@0.39.0
	windows@0.51.1
	windows@0.52.0
	windows@0.53.0
	windows@0.54.0
	windows_aarch64_gnullvm@0.42.2
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_gnullvm@0.52.4
	windows_aarch64_msvc@0.37.0
	windows_aarch64_msvc@0.39.0
	windows_aarch64_msvc@0.42.2
	windows_aarch64_msvc@0.48.5
	windows_aarch64_msvc@0.52.4
	windows_i686_gnu@0.37.0
	windows_i686_gnu@0.39.0
	windows_i686_gnu@0.42.2
	windows_i686_gnu@0.48.5
	windows_i686_gnu@0.52.4
	windows_i686_msvc@0.37.0
	windows_i686_msvc@0.39.0
	windows_i686_msvc@0.42.2
	windows_i686_msvc@0.48.5
	windows_i686_msvc@0.52.4
	windows_x86_64_gnu@0.37.0
	windows_x86_64_gnu@0.39.0
	windows_x86_64_gnu@0.42.2
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnu@0.52.4
	windows_x86_64_gnullvm@0.42.2
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_gnullvm@0.52.4
	windows_x86_64_msvc@0.37.0
	windows_x86_64_msvc@0.39.0
	windows_x86_64_msvc@0.42.2
	windows_x86_64_msvc@0.48.5
	windows_x86_64_msvc@0.52.4
	winnow@0.5.40
	winnow@0.6.5
	winreg@0.10.1
	winreg@0.50.0
	winreg@0.51.0
	winreg@0.52.0
	wry@0.24.7
	x11-dl@2.21.0
	x11@2.21.0
	xattr@1.3.1
	xcb@1.3.0
	xcursor@0.3.5
	xdg-home@1.1.0
	xkeysym@0.2.0
	yaml-rust@0.4.5
	zbus@3.15.2
	zbus_macros@3.15.2
	zbus_names@2.6.1
	zerocopy-derive@0.7.32
	zerocopy@0.7.32
	zip-extensions@0.6.2
	zip@0.6.6
	zstd-safe@5.0.2+zstd.1.5.2
	zstd-sys@2.0.9+zstd.1.5.5
	zstd@0.11.2+zstd.1.5.2
	zune-inflate@0.2.54
	zvariant@3.15.2
	zvariant_derive@3.15.2
	zvariant_utils@1.0.1
"

declare -A GIT_CRATES=(
	[display-info]='https://github.com/greenhat616/display-info;093a0c2174edbeb1f5b275b9ae9061c6e9c91cac;display-info-%commit%'
	[gunzip]='https://github.com/TechHara/gunzip;adfed97f7fa4ad705364e7fc151eaaf0950cd6ba;gunzip-%commit%'
)

inherit cargo desktop xdg

DESCRIPTION="Clash GUI based on tauri"
HOMEPAGE="https://github.com/LibNyanpasu/clash-nyanpasu"
SRC_URI="
	https://github.com/LibNyanpasu/clash-nyanpasu/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"
SRC_URI+="https://github.com/liuyujielol/gentoo-go-deps/releases/download/${P}/${P}-node_modules-pnpm.tar.xz"

LICENSE="GPL-3"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD CC0-1.0 ISC MIT
	MPL-2.0 Unicode-DFS-2016 WTFPL-2
"
SLOT="0"
KEYWORDS="~amd64"
IUSE="clash-rs +mihomo"
REQUIRED_USE="
	|| ( clash-rs mihomo )
"

DEPEND="
	dev-libs/glib:2
	dev-libs/openssl:=
	dev-libs/libayatana-appindicator
	net-libs/libsoup:2.4
	net-libs/webkit-gtk:4=
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
"
RDEPEND="
	${DEPEND}
	app-alternatives/v2ray-geoip
	app-alternatives/v2ray-geosite
	clash-rs? ( net-proxy/clash-rs )
	mihomo? ( net-proxy/mihomo )
"
BDEPEND="
	<dev-util/tauri-cli-2.0.0_alpha1
	app-misc/jq
	dev-lang/typescript
	dev-lang/quickjs
	sys-apps/moreutils
	sys-apps/pnpm
"

src_prepare() {
	ln -sv "${WORKDIR}/node_modules" "${S}/node_modules" || die
	# pretend we have prebuilt binaries
	mkdir -pv "${S}/backend/tauri/"{sidecar,resources} || die
	touch "${S}/backend/tauri/sidecar/clash-x86_64-unknown-linux-gnu"
	touch "${S}/backend/tauri/sidecar/clash-rs-x86_64-unknown-linux-gnu"
	touch "${S}/backend/tauri/sidecar/mihomo-x86_64-unknown-linux-gnu"
	touch "${S}/backend/tauri/sidecar/mihomo-alpha-x86_64-unknown-linux-gnu"
	touch "${S}/backend/tauri/resources/Country.mmdb"

	jq 'del(.scripts.prepare)' package.json|sponge package.json
	cd ./backend/tauri
	# only build the excutable
	jq '.tauri.bundle.active = false' tauri.conf.json|sponge tauri.conf.json
	# disable updater
	jq '.tauri.updater.active = false' tauri.conf.json|sponge tauri.conf.json

	default
}

src_compile() {
	cargo-tauri build $(usex debug "-d" "") || die "cargo-tauri build failed"
	#pnpm build || die
}

src_install() {
	dobin backend/target/$(usex debug "debug" "release")/clash-nyanpasu

	newicon -s 32 backend/tauri/icons/32x32.png clash-nyanpasu.png
	newicon -s 128 backend/tauri/icons/128x128.png clash-nyanpasu.png
	newicon -s 256 backend/tauri/icons/128x128@2x.png clash-nyanpasu.png
	newicon -s scalable src/assets/image/logo.svg clash-nyanpasu.svg

	make_desktop_entry clash-nyanpasu clash-nyanpasu clash-nyanpasu 'Network;Development' 'Terminal=false'

	dosym -r "/usr/share/v2ray/geosite.dat" "/usr/lib/${PN}/resources/geosite.dat"
	dosym -r "/usr/share/v2ray/geoip.dat" "/usr/lib/${PN}/resources/geoip.dat"
}

