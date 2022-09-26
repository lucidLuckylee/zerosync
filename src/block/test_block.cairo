#
# To run only this test suite use:
# protostar test --cairo-path=./src target src/block/*_block.cairo
#
# Note that you have to run the bridge node to make all this tests pass
#


%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from python_utils import setup_python_defs
from transaction.transaction import TransactionValidationContext
from block.block_header import ChainState
from block.block import BlockValidationContext, State, read_block_validation_context, validate_and_apply_block
from utreexo.utreexo import utreexo_init, utreexo_add

from serialize.serialize import init_reader
from block.test_block_header import dummy_prev_timestamps

# Test a simple Bitcoin block with only a single transaction.
#
# Example: Block at height 6425
# 
# - Block hash: 000000004d15e01d3ffc495df7bb638c2b35c5b5dd0ba405615f513e3393f0c7
# - Block explorer: https://blockstream.info/block/000000004d15e01d3ffc495df7bb638c2b35c5b5dd0ba405615f513e3393f0c7
# - Stackoverflow: https://stackoverflow.com/questions/67631407/raw-or-hex-of-a-whole-bitcoin-block
# - Blockchair: https://api.blockchair.com/bitcoin/raw/block/000000004d15e01d3ffc495df7bb638c2b35c5b5dd0ba405615f513e3393f0c7
@external
func test_verify_block_with_1_transaction{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr: HashBuiltin*}():
    alloc_locals
    setup_python_defs()

    let (block_raw) = alloc()
    %{

        from_hex((
            "01000000a0d4ea3416518af0b238fef847274fc768cd39d0dc44a0ea5ec0c2dd"
            "000000007edfbf7974109f1fd628f17dfefd4915f217e0ec06e0c74e45049d36"
            "850abca4bc0eb049ffff001d27d0031e01010000000100000000000000000000"
            "00000000000000000000000000000000000000000000ffffffff0804ffff001d"
            "024f02ffffffff0100f2052a010000004341048a5294505f44683bbc2be81e0f"
            "6a91ac1a197d6050accac393aad3b86b2398387e34fedf0de5d9f185eb3f2c17"
            "f3564b9170b9c262aa3ac91f371279beca0cafac00000000"
            ), ids.block_raw)
    %}    
    

    # Create a dummy for the previous chain state
    let (reader) = init_reader(block_raw)
    let (prev_block_hash) = alloc()
    %{
        hashes_from_hex([
            "00000000ddc2c05eeaa044dcd039cd68c74f2747f8fe38b2f08a511634ead4a0"
        ], ids.prev_block_hash)
    %}

    let (prev_timestamps) = dummy_prev_timestamps()

    let prev_chain_state = ChainState(
        block_height = 328733,
        total_work = 0,
        best_block_hash = prev_block_hash,
        difficulty = 0,
        epoch_start_time = 0,
        prev_timestamps
    )
    let (utreexo_roots) = utreexo_init()

    let prev_state = State(prev_chain_state, utreexo_roots)

    # Parse the block validation context 
    let (context) = read_block_validation_context{reader=reader}(prev_state)

    let (utxo_data_raw) = alloc()
    let (utreexo_roots) = init_reader(utxo_data_raw)

    validate_and_apply_block{hash_ptr = pedersen_ptr}(context)
    return ()
end


func dummy_utxo_insert{hash_ptr: HashBuiltin*, utreexo_roots: felt*}(hash):
    %{
        import urllib3
        http = urllib3.PoolManager()
        hex_hash = hex(ids.hash).replace('0x','')
        url = 'http://localhost:2121/add/' + hex_hash
        r = http.request('GET', url)
    %}

    utreexo_add(hash)
    return()
end


func reset_bridge_node():
    %{
        import urllib3
        http = urllib3.PoolManager()
        url = 'http://localhost:2121/reset/'
        r = http.request('GET', url)
    %}
    return ()
end

# Test a Bitcoin block with 4 transactions.
#
# Example: Block at height 100000
# 
# - Block hash: 000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506
# - Block explorer: https://blockstream.info/block/000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506
# - Stackoverflow: https://stackoverflow.com/questions/67631407/raw-or-hex-of-a-whole-bitcoin-block
# - Blockchair: https://api.blockchair.com/bitcoin/raw/block/000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506
@external
func test_verify_block_with_4_transactions{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr: HashBuiltin*}():
    alloc_locals
    setup_python_defs()

    let (block_raw) = alloc()
    %{

        from_hex((
            "0100000050120119172a610421a6c3011dd330d9df07b63616c2cc1f1cd00200000000006657a9252aacd5c0b2940996ecff952228c3067cc38d4885efb5a4ac"
            "4247e9f337221b4d4c86041b0f2b57100401000000010000000000000000000000000000000000000000000000000000000000000000ffffffff08044c86041b"
            "020602ffffffff0100f2052a010000004341041b0e8c2567c12536aa13357b79a073dc4444acb83c4ec7a0e2f99dd7457516c5817242da796924ca4e99947d08"
            "7fedf9ce467cb9f7c6287078f801df276fdf84ac000000000100000001032e38e9c0a84c6046d687d10556dcacc41d275ec55fc00779ac88fdf357a187000000"
            "008c493046022100c352d3dd993a981beba4a63ad15c209275ca9470abfcd57da93b58e4eb5dce82022100840792bc1f456062819f15d33ee7055cf7b5ee1af1"
            "ebcc6028d9cdb1c3af7748014104f46db5e9d61a9dc27b8d64ad23e7383a4e6ca164593c2527c038c0857eb67ee8e825dca65046b82c9331586c82e0fd1f633f"
            "25f87c161bc6f8a630121df2b3d3ffffffff0200e32321000000001976a914c398efa9c392ba6013c5e04ee729755ef7f58b3288ac000fe208010000001976a9"
            "14948c765a6914d43f2a7ac177da2c2f6b52de3d7c88ac000000000100000001c33ebff2a709f13d9f9a7569ab16a32786af7d7e2de09265e41c61d078294ecf"
            "010000008a4730440220032d30df5ee6f57fa46cddb5eb8d0d9fe8de6b342d27942ae90a3231e0ba333e02203deee8060fdc70230a7f5b4ad7d7bc3e628cbe21"
            "9a886b84269eaeb81e26b4fe014104ae31c31bf91278d99b8377a35bbce5b27d9fff15456839e919453fc7b3f721f0ba403ff96c9deeb680e5fd341c0fc3a7b9"
            "0da4631ee39560639db462e9cb850fffffffff0240420f00000000001976a914b0dcbf97eabf4404e31d952477ce822dadbe7e1088acc060d211000000001976"
            "a9146b1281eec25ab4e1e0793ff4e08ab1abb3409cd988ac0000000001000000010b6072b386d4a773235237f64c1126ac3b240c84b917a3909ba1c43ded5f51"
            "f4000000008c493046022100bb1ad26df930a51cce110cf44f7a48c3c561fd977500b1ae5d6b6fd13d0b3f4a022100c5b42951acedff14abba2736fd574bdb46"
            "5f3e6f8da12e2c5303954aca7f78f3014104a7135bfe824c97ecc01ec7d7e336185c81e2aa2c41ab175407c09484ce9694b44953fcb751206564a9c24dd094d4"
            "2fdbfdd5aad3e063ce6af4cfaaea4ea14fbbffffffff0140420f00000000001976a91439aa3d569e06a1d7926dc4be1193c99bf2eb9ee088ac00000000"
            ), ids.block_raw)
    %}    
    
    let (reader) = init_reader(block_raw)

    # Create a dummy for the previous chain state
    # Block 99999: https://blockstream.info/block/000000000002d01c1fccc21636b607dfd930d31d01c3a62104612a1719011250
    let (prev_block_hash) = alloc()
    %{
        hashes_from_hex([
            "000000000002d01c1fccc21636b607dfd930d31d01c3a62104612a1719011250"
        ], ids.prev_block_hash)
    %}

    let (prev_timestamps) = dummy_prev_timestamps()
    
    let prev_chain_state = ChainState(
        block_height = 99999,
        total_work = 0,
        best_block_hash = prev_block_hash,
        difficulty = 0,
        epoch_start_time = 0,
        prev_timestamps
    )


    # We need some UTXOs to spend in this block
    reset_bridge_node()
    let (prev_utreexo_roots) = utreexo_init()
    dummy_utxo_insert{hash_ptr=pedersen_ptr, utreexo_roots=prev_utreexo_roots}(0x2d3ef8215980ca7bfe3aea785eb7a2f234eb33418ef4bc87683ca23287cd309)
    dummy_utxo_insert{hash_ptr=pedersen_ptr, utreexo_roots=prev_utreexo_roots}(0x1aa9272136be702146acae34cf02dfaed63288404e0e5842ae3b60341848779)
    dummy_utxo_insert{hash_ptr=pedersen_ptr, utreexo_roots=prev_utreexo_roots}(0x75f708000a3e08f9d6f01ced23f5e5d510bdf6dfa6d4447858586d4026b516e)


    let prev_state = State(prev_chain_state, prev_utreexo_roots)

    # Parse the block validation context using the previous state
    let (context) = read_block_validation_context{reader=reader}(prev_state)

    # Sanity Check 
    # The second output of the second transaction should be 44.44 BTC
    let transaction = context.transaction_contexts[1].transaction
    assert transaction.outputs[1].amount = 4444 * 10**6
    
    # Validate the block
    let (next_state) = validate_and_apply_block{hash_ptr = pedersen_ptr}(context)

    %{ 
        # addr = ids.next_state.state_root
        # print('Next state root:', memory[addr], memory[addr + 1], memory[addr + 2], memory[addr + 3]) 
    %}
    return ()
end




# Test a Bitcoin block with 27 transactions.
#
# Example: Block at height 170000
# 
# - Block hash: 000000000000051f68f43e9d455e72d9c4e4ce52e8a00c5e24c07340632405cb
# - Block explorer: https://blockstream.info/block/000000000000051f68f43e9d455e72d9c4e4ce52e8a00c5e24c07340632405cb
# - Blockchair: https://api.blockchair.com/bitcoin/raw/block/000000000000051f68f43e9d455e72d9c4e4ce52e8a00c5e24c07340632405cb
# TODO: fixme 
# @external
func test_verify_block_with_27_transactions{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr: HashBuiltin*}():
    alloc_locals
    setup_python_defs()

    let (block_raw) = alloc()
    %{
        from_hex("01000000337b169fca6d6e3a0872ccb84489c86f877077f9208540856b090000000000002b8e6abbeb371d970fe46b341d57c1fe5d5f6fab97157b5d89f3a2a9240f59ad7519574f0c350b1a2389a3261b01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff08040c350b1a024f02ffffffff01b06c4e2a01000000434104d3b7f6be3e63d007cf54c3535f79eabd821bc660c518c0361e6f8820652272241a3404f4a0404e5cab770fe6364c5141dae78d5f576e4ed0e395c92ed217a0e4ac0000000001000000046f30465d60edea07113c80ddae9d0d1dc1810cee793162b3a5aa5de2a6bb9a0c010000008b48304502207dd1c08b2f570ec7f689616c513c83c84d0b7a805b2949f7a5325fc3ed2ae560022100822f6e60fcee5125ec2f2fa4b0888f7e8720f0a64d64d6268b8159519c66cb450141044fb4fa3bf52d2e60397bf2dd5f537b741baaa89ff7d53fe9c5b2d24e2f3354c830d84869f6270ca3980ae38d7f6ad10dd5bae6b4df4b26748d43f1a26779f89effffffff20dd9ec6b7575eab34847adaaee7dab5cc272e74e66b1bfd89fb30cfa2f24643010000008b4830450221009e7d8e474bfb7dd17c232ace00bfbe33c2b0632a96547f057f43cbe4be2730f0022048db9043973be248a7aa6cd1d738162fd6a4026707ca4afdcf2e022cefbe64b501410426915eab49e09204c13dc2cb80f2ed5f72e88c3d60eb33a376b7c895e582f3a0467773db479126d144affd6543dec22e4591e0bfbb4138e0d894a4f329f20cf4ffffffff06221ea32490ee3dea601d5509021c9cdbd91f5a3544e34b5549b47f85defad4000000008a47304402206f250dd00e508ff469e141a8318c2e9f0259402c993fc8a1eaef5901cb7fbaeb02200398803d2aba9f39212be724841ffdc4bea04394492a41a780fe3e1226e1643b01410405cb0ef15fc8b1e670c5862e2d28ccea251dffc066fb6745f0a30c7db7202de2d33597ba9d5a6d73ee290667beb76ffe290051a37643d807da787734021be7adffffffffc3794dadb8fc426d771459146a1101c1edde9534f379a0b811963a0aa933b309000000008c493046022100b369e4b65656b8658a7f008190def56ee1e89fb1c31af3b15ffa27ad7b6bc3ae022100ed0998f1eb8653c5dc1b9ba8feb244624386d4cf3057d7642e75961ecca5cf79014104fe412179bf7ca1a276ddb69b067ee5624012c9ee5d8a75c350cd05593a96a2d55b66d1c99c2856b475ce3f5a7acb56ca223a5b6ebd67d83bd361c04e82c466d8ffffffff0203fd5449000000001976a9149be0c92d7c4b93f9e5e1f282df8228b2a4a4d61e88ac805d9b44010000001976a9143e2998c9ea7cf49b29d9c9dff2a441918055fd5d88ac0000000001000000011e5b107b2666baf1f672f978af5e9702c3884d39e241ce958144f81b94213270000000008a4730440220598fd6fff4496df0298b8ef34e23dcf874e4191b59c63c143c4136bceae5c9f902204ac900c85f519bd7d34663ade535a7dee4d18c295f9838b32620612b208a6eb6014104396bcfd5027b97b54bf4a71ad548b29360d3932939ba495456d696d3d4e424013fc6164ebe1d6cdaef2fc33957d97dca769f67e5effae5753d3ba04776fd045affffffff0100ca9a3b000000001976a914d4d1cf6b3ee3d1717085f480261b6766a5eff6ee88ac0000000001000000018ca6e6ae0d25797ac5414261dd18bdc23a9d98fe5179d21ee87650f00ca3a585010000008c493046022100ef38a2788a2c32dbd85bb4d06338f4bf057e06191e573333c0da4a822cd16f6b022100b0d30c1525bb345fb163308f0575265f4b8b7e770e732ecca66009f9fd474515014104a31e3d62fcd881683fcacc0bc4c5242cd6ae12e9143a5902464dbc3a6832b1f90dee86f0a496b4df9201a037a5b69b0fd3f499dada293255ea32abe467ff0a19ffffffff0200c90c6b000000001976a9147491dbb7c46adca2e6cf7caf0a39faf111df222488ac00093d00000000001976a914d9d8d1e0a7dc756437228203dbef3c5158ca33cc88ac00000000010000000295986e44c5a4e10b1a4f6eb167e062e3ac9fdb454d0caf6a627ac1dd5953d8320b0000008c493046022100bc804afb542cb7711aead402c9e9b0094dc333ba1a2124924afb2e8c04fc0440022100b3c7847edf34133dda4d5b2c5ccf083b127db0ba9167a358e6e03a5ce89414df014104ba8d697def6ffa4a74740071acd256f016647a3ae0d220b86e9b57c376b6a3bc1de60af265a86a4844aa7da5444e3e2c41ce53d8362aec2341a0a4785e4432d0ffffffff6e3f580cb3f7c6c25469d76b39e5f538dc696569ece67bdd08ab61d14fdc85a8000000008a473044022043c79b5b4a9840ecaa3b88a2b64250e904d217c74b713eef3d159ebce147b45a0220419eb01803de4bf341ad747193ef14a05250fc08301058a4643315c57a85ee30014104010e362c5a2aebadca2661e297d7b400b5407dd2bc2208ab01d34601bfcfff663aa232a9092dd661c083db62ee148b9d82a19ea42da6e52fce27097f9ea714f2ffffffff0200a3e111000000001976a9144acb44c709a5cbea873173470501d7dc2b87dd2088ac61c5b151010000001976a914009834cfbac2fd7a372febd23de695cbd0d3941a88ac0000000001000000041895be32b398be43225f68db49ecd67ed96b6a8466cc1f6e111c241507e14954010000008a47304402204123e8f7c767433d184a894d01880829d338f9859e234f9d8d97e1d8db3c539e022047062c0aecfec9db2ee45925166d089f9b51e6a67779886fd2cb0876bd351b77014104a8955194bf8bcf16b9ac57a322ed217d8c1c5bba77f7835d053825f2c552b91ddba554159ef855a810bc455ecbc70814630e9dd711a9e7172445f8313f9f301fffffffff2974cb2c4369e722b58003334bcb1d162b47380d183e0cfb265f1195afd05b30010000008b483045022100b27afef63898cbc5817e6fe07aaa3f4419ce4f11e0e9ceec0dc087864fb9c18a02203eb2bc75e893f8a3d8c238c61636788d63ff5815acc60390a3e58797d8a1caf30141041a91ccb3e3c907117c646c99a583fc1c7088c9a994fddeca20d0925721b4a031238c4960acc9bea63d25a9e206f7fd9e7e70a1899f867a02bed380b668204507ffffffff4d0297643e1f2d712403d288f407985b8d6b4b346a01e9c0bafbc16fe7b9cdf6010000008b48304502205aa4429f32999d37952733005b16d790255bce0b61cc3c47199cb2306e3a0e11022100f61bc6c6a5e199fa40c9d7c59de7a0ed616545369f4108e277d42415f30df9a5014104f764f5f6f6fffd30bb7c2d65d8dfdacad68ed9c42122529eefdbaf62334a4551c3fa7173a738be3d7fb1c43cbdf4dec7dec080cd688bee7859303d4da08bae04ffffffff9d27923a4ee7d2e2f07c1ddcaf69238cd4b3e8a5bec1ee476f794257fc1020a0010000008a47304402204a6d5a4fbc340048678953e614c7854ebcc02369201dd5eab9e7cf101b57bcfe0220039a9eba8c9a4987712e88259a377e2f59d72ef31198a90ea8f8679544f38fc80141042bfd454d9b3fefb24c559904a929a8e80feec5ca3568282b2c261589028aa502c617c9fe5a5eff267b442f458c0519fbac091fa86524f7e762b664c406895e0cffffffff02c03b4703000000001976a914d058bb44a29fbb7154813071ff5724e70f291fa288ac4031354a000000001976a914710b9675b992c49d2e6747e11541d761a843178488ac00000000010000000b0293952b200c5c41d37c2597cb8c8d922076c7b487721f068d3d80a4780546b41e0000008a47304402203b042d2cf26620ab40ac3a412adeb6b0db59f9ef0895e0c6322105aab43d38100220764500de0820d45895ea3085df39da0a258d740241585d8cb4250f388fee867e014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffff2eef2c279d0937c3c411f6dc47ddaeda30948e047db42d4778266034ed0a9fd7020000008b483045022100f8b56eae18a6a6b1d430c3ec3b6344275798e46b004ec3c82f1f5246c46e822602207220f01730df038fdc68638af773d237625f0c81e3bad2799236911b39eedc84014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffff3566a37ba9d84b50c92898eb6fa432b24d396088ab5168ceda14719c510595241a0000008b483045022070f4692240f6454901a4cb7a9c9df2c69012a25046ecf835d4421a2a46d85899022100f581736fd94fc5bf9d91d73662bf0ddd9124c9a5a3bbd50496f506ccd5c8b64a014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dfffffffffb96f14e8fb1e4f2d62ddd90b40870ba6d67d175b2482907e8da7e650710a2fa210000008c49304602210087b06c83732de2bd53bd40d02f222758208aefa7807472bcdc5410f2c2d956d8022100dd7a9ff7b2cd573f7f6d4efdcc7b26469367054817ed00c904ad301067887809014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffffeb94b896deb98b30129554b38a601d14a2c39d788278d9b455e89840a9b401b9170000008b48304502207082da6353d35e086c697f3423bb0154ddd95a56642e97b706c8b7c6eeee68c6022100802b1bf0a2a907de5bd253c64ca1b504a556d10e999c3fca965b4e6507a3f61f014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffffa8fd0e6fc70da33dbf6082154626ea5e2921036c95601ad7aeacdb3edd1fe9301f0000008b483045022100ad11ee155dc705ffe65242a3ca7e385658ed3145104b123134a05e93bfcf7fc40220696086c85e44ebced3ca2bb09c2524af305436d5cef9a7b6f182057c9c6984d0014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffff4c293e7c03d73c04ddcb929b823b3529d69a5f083e57696184dc46e82d470c731b0000008c493046022100b75f82fe1cacf1e4562ff94da9cfaadcf0172354de8840bf2a63fbda9e2c3bbc02210086a89f98479c501cd3a9422bf525ea23bd5cc7666a92f427531ef239097fb056014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffff9417c8bb5cd8a16793281045d0a3d0e4cf647dddc825ec8ac856aa4cec2bbc68210000008a4730440220390d1aaf5f57111ec127d441e95db3501562df0c718a3cccd0b250bc032c4e4c022073f10f5158e350caee9d5d1f4b914050ffd3665d7e2c3b4c114341388373110c014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffffe1e7cb3bb033b285a25eeac19d64d8da6cc37dd958c84731be88da2f6f6c7ead1e0000008c493046022100a2c1d479483ecec22a3a700c835d5de76b48295bf7f2b36ee88f787a9412f815022100bd2bf8faf70ae0bddfe934632c3b2d8e903582bf71b794d9eef02d11629c7703014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffffe6e1b167485e34421509c45c6abc6a633ed7f73b738ae59d0ff242181a56bdfa180000008a47304402205b5b8943b2bcac3b45d1d14ceeeaee65d7cfb75cfed6e6ee0a01f3997d59c67202201292b299276d87f9f984910ab49255942a1fa18299c9bcd1c97d72e7a53c97f8014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffffd9c7658fa74f89ac6bb7b3e5c5bee6ad9f58364757a1b72f70fc34df169c4d57020000008c493046022100fa07208846e3db37ff0c2983c7011abf624f8c6e04723de6a5b3ae43b8eaf92602210080ad8fb6acc46b650dd18e1660c79cda78ff074df115483bbc1c99deec6725ef014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffff0201df8f00000000001976a9145e887243ef1afec2d120f772ade1a5b30a9df16088ac005f8277010000001976a91487e425d9db51b19b8045a06edd3609e5dce0ca6d88ac00000000010000000fbb2d659655961ed5e02ff6ee53b8bdf04715d03c72ec0b95bf35dd978beb0103000000008c4930460221008931bfcca1d2549967380c5a23f0204f370631bc77cdb19cfc4292b8b741e4d7022100c026d7a18122307761c192d5eb43a30a9561ff744a3af348380ed5c5be31f90b0141049d56422774ed29031634ba6d0aa8f5687bede2c482e793ccd08e22a07f61592ba09011081987129f597a1e21f33df3798dbd7eb59673c24ee4782c47613c23d6ffffffffe994d48d2c9bd791c42df57a345fa39aa02ef4ac767d0d778db3063aa87dbb32010000008b4830450220773abb665e137fe0d5e5bfe24fa2d9547b537673a8d6fc4a6dc958f543022e4b022100bba85537de351302e9a3e851a7f0cfed139fad3e8da460e5d96b049254666e03014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffffaa869da11d1747fe6f687411484490f57add5e34af25ec16cb360a40ac90eaf1000000008c493046022100c42b7e9f59c8edd7890c0e6c675a64db56661371217e65747569ad045839691f022100bc74b03cff4e7d6e91ec48f60645e329ce45230232da4f7974fa9eae55187513014104709c4494cd9e7e9f22d1d4aafb23ba2b93e64f80b2a927728cb2660aadcdc44849be8a43a567b2658f77da01af52d92a1fd0f0ebbb1d84114d06138de6de258fffffffffdb44a3f2fee10ded395f80c3d85cb4ac426cdfe15c703b7c343023ad5e2711e8010000008b483045022100cc0d805a9034501ded71e460a8334fa354414a697db2dfd03e9c308b303a67940220475a48d61e2ab187fa659bde5e393198d29a2d665e01f5ea107714f0bde7db47014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcfffffffff9964249135d915061c4fe0abb615c11e15ab6da152655c10494bb945a8ff5e1010000008c493046022100c3757a49cd493c28908b76981d86063ca9576bc8609e9c26f5bb3dbbe1c7cd7b022100d2e03a2fdcaef43c49fcdbfe9af35e6499a67fb3cb5fc4e276fa61bbc0c716ea014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcfffffffffa7b64c9ce9149d59b124b98de8fb4d1377533870f9d1bcabaa8c62f8e6af0bc010000008c493046022100865b44f91bdd369c375f3ca2948125296abe192417b7c02ecdbc8ff04d9290fa022100c667f530e0ad120585c40b79e6dbd32b35a587cd6adb6341ee1865cd9e70fa22014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffff31626cdd4573ede21df90de50c735712f89dd1024d6c649cd6ae0ddfa8b9bc4d000000008b48304502207a03e2326a10193d773e8bc58437d7487157c14de87ad8971dacd0daa69c658902210082bf50569c733bb7a0d20c699c26df0844c8f14fa54b7e8da3a8065d09a5b7de014104c55d031471f1d2ee4c012e9b4d0c7715270b82bc056e4d399963945242bf35b9e9015045acdaff8504d85dd7441ca7b2a889d50c2d02cc1db0549bd209c087dbffffffff294b10ac512c8787b8721493f8fdddb795774c9ef845af4e4351857df78d1a63010000008c493046022100ab262ed21493f8c87b5d8a0f216b533462b24e0f8a4757629aa9c8b7881448ea022100a244b0b13fd1241a01f3b8782ce106c74fc9dbd3d0036cdd74b6d3f7da900584014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffff2a656fb098d86fb72c84751cff3d3384795e86672ed23f7c6d079b69f675860a000000008b483045022047f96442d076ecc9f7be242d5a152069463dc073e1f57061119dab9a30ed4e5c022100d244392ab95e1212ba829b31cf5058dc9e95ac4aaa0220383a7efc4ba40ab12d0141049d56422774ed29031634ba6d0aa8f5687bede2c482e793ccd08e22a07f61592ba09011081987129f597a1e21f33df3798dbd7eb59673c24ee4782c47613c23d6ffffffff3789f1a178453af018f0c58070aee43904f228b55a9ad6447f6c52af922b2cd7010000008b483045022100dd68e371a184386c856ab447f2eb597fbb16a91955c97c50dd18d85f56a0460d0220008deec20ac2e9377029bc4f9318350e6e64e9d2704a0f3d874420e0eace87b2014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffff3b8813d9f00fd56f4bdc0308918350bed990a993e6c327e6f15c381d2f20a55a010000008a47304402207dbb6ffac1191bb081100d377c9c630aec994f1ff18890c6ce4359f51bc5f0e102201d4df6720bb413197d02cdab9da73115ddc31cb73a73463e230f9ba1065480cf014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffff3f92e969056272f9947bffd29ea7f59911c86d68f92a341b023b616e808531e6010000008b483045022100d201717a035ee47c27027315c3796541a4fd7c8c69fc3395acd6a16934eeb5aa02203f83ae06fc4878b0bb00d5df830945fadcde308ac54900aef22cdc0f70de6887014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffff440fd37fd7226844422116ee2ae6c74e726699445f145ed10c1e4bd4821b85f3010000008a473044022070927f985a3f35ee011341815cfaee89ea0a4ab1f64c08f8a04898677f80f2de02206330ae108d2b7e1a12d5ce8997429132a15a0a4071bc46f254b4c2f5bee91f66014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffff45d40a8c169e1f0597e41c654ccc283e2f75c39d0cff4b8e3f12a6d8dee82ea4010000008a473044022049356c740f5abecf0c35289bb45fb61987100cd14e32192b79fbd63e4d422eec02203d2163bb8b69d513198f5356a05466c2a4be7cbd11b704b091853a942127cba5014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffffa2812e761a68f9b4b577ad53b0b36e4515ab9d8f745c34c951ca2aa968929bf0010000008b483045022100af1637ff33bc889d5eda5caea386364b6eebf52534f628cd3bcc63923e4c12b9022054c55702660867782576d9b9e20b653717f5f10a83fc527093fee98aa3ecec39014104805eea97b3fb36633c812cdfd46e795302d047626097fe484c12762aa446a8e52566cf7cd30641d9dc943cd9d93791c3f0ea2df08e5a094e62eeba9357d6a3dcffffffff0220d61300000000001976a914e0337de3f52f72c5ad39be2051dd0fcf6a2549a888ac4064de22000000001976a914a0c15c6b708a799280ca76d4af9b261a046db57088ac000000000100000001d64970ab415fb30f88c4a514ca21ba00b7f64784527e2cde5f60d6eaa14d7676000000008a4730440220171204d570da1ee042c9fae79329d31fc7927a2b0c714cccd128c99ffad5816702201753dffc9302a38caf0628e45da7137452891efe728800409c8d8289a8338e6a014104d047c29f07116fc43760ae22aceb0cc56f7d369e25c8a6ee65845d606a648aede34619f69180a2001d260805d3e016b5f4adb50982442763d89a89be1be1fcf1ffffffff02e0106c57000000001976a9145bc22ee3fd43561807f464f1ca717676a2dd086688ac00a50f2d000000001976a914646ade23a078c0c8869a6ee231cbd2c8044d165988ac0000000001000000017f4d4452444be5ebf3b85ad0492e0f080c17a23fd3657c3ce9a6e5a96b58ee3c010000008b483045022100a420c3259df52e832f958881b83469ac23f199eb1fc3a1079de39651a59e304c02200f9fdcfeb03437ee4b915b234d65c96e3910bb24c83c3e51fe1e7ea19a8861cd014104d08f33bd5d1421e82e09ad00a2babc3e01bfd6ef7a2561332398e092ce781b354036b3d1a41a2584282e4833a94144390bc284955c8e4ae2413bf16861c81320ffffffff029aa77f39000000001976a9147e2a48f07c4970fe921db27fd502231beb8b1e3c88ac00475a31000000001976a914646ade23a078c0c8869a6ee231cbd2c8044d165988ac0000000001000000061c83b7bb451e1e08d2cbf0ae4e3f66ae1e719e9887846826e895daca71a992cf010000008c493046022100a4d44c1a0e6512569e6c885851f5eabdedcd6c887b89e7ea09e69bdfda49697a022100ebacc14116a02f2ef02e54bdd79f83fc5b25558eff674af95b1e1542e7bbb43a014104cd7534aeb8ccb377d406d6f114511fef6c00592c6237833c80bb06c021f85782f6ca7af76daa1c0cecd7f820a7759286f7427e7b52bac5d6be241555a1a8fe44ffffffff32a251481be70ce8c0dc85f5420f976e1800073ff704ebe18b6f33d20ccf6dbb010000008b483045022052680e23720034586e49235dfaf16810f1c5cd8504adc63909d16ba03936f38b022100afab7dc05fece45375c2cde478b626f2a143a8249b14046ae4dcc2b06a4a9af8014104cd7534aeb8ccb377d406d6f114511fef6c00592c6237833c80bb06c021f85782f6ca7af76daa1c0cecd7f820a7759286f7427e7b52bac5d6be241555a1a8fe44ffffffff3aa11d72e1f7bf99d191f69ee0b769c561c0e7638905714a88a3b12b84097479010000008b483045022100ec43f1529db54cf144225f57a6618a3cc5fbad83e0f698aedd9300f7ea1d9e5202202815a0359f57fe0fd75bdd9dcbe5670ffbc3bad68c1fbfaf762e1944e0cc51ed014104cd7534aeb8ccb377d406d6f114511fef6c00592c6237833c80bb06c021f85782f6ca7af76daa1c0cecd7f820a7759286f7427e7b52bac5d6be241555a1a8fe44ffffffff699a74e6fe789c9b1f08efa44967a657976954dc083cfdf33c75c8cec618e4de010000008a473044022063e7ddf06310b2404bdd939b75132186e6a8297439791d09e9ef1ee4efd54bed02204742114425f7ca200627952f4dac609b715d0af8c1e017f7fb8cb12925f8aa2d014104cd7534aeb8ccb377d406d6f114511fef6c00592c6237833c80bb06c021f85782f6ca7af76daa1c0cecd7f820a7759286f7427e7b52bac5d6be241555a1a8fe44ffffffffa696627292eb9d65a1e773ed00501d0105c1343882faedcf28bf22f245312ce0000000008c49304602210080ea50d73add42364e972840c7ac0c245a0f50d9115e2b3f5b1fe00bd878573802210081bfa694eb0720e4d7a0f8ea5ee338b3efbabb2fc931ecd712ef5eba26bb6a100141042fef14147403bf3ca00a02b711634e31f089f063495597abf03f543570438b7a535d05d28f920ddded7b91da6b13bec34ae6b47d7a71836ae5beafbe2d9e3a83ffffffffad197179714981e90733035ce427cf4e0a459b7f2e9c45fb43a2ad608d9b519d010000008b483045022074ef42300a699aac5bdd3d6e91ff49c4f10fb635b20be9e07081ae02b1a34a0d0221009176a24929e6a2857ffecbe8f5e7880acf4fb0d03eb6fabbdf456c58a3216129014104cd7534aeb8ccb377d406d6f114511fef6c00592c6237833c80bb06c021f85782f6ca7af76daa1c0cecd7f820a7759286f7427e7b52bac5d6be241555a1a8fe44ffffffff02a00bd100000000001976a914651823e7df483fede3817eda4f927a25731f8e5488ac0065cd1d000000001976a914cc4b15d990c3285b0d1d5298c4c96c47b259db6288ac000000000100000001ca9225c58964ba5639ff954e4cf228fd335beed42a74c65d974fbaa449a6b8a1000000008b483045022100f820bd4fdf4e2828063e6cccd88afd8016743655ab0557028b887c28514fae8e02203ad5e2c056268f8aa133f8cd4c6d16599091690981ddf9022d70e8a592689adf01410409635dd629c96bfd777e35b2649dc40693d1e2cd6ca0c194b39b3b3036a7aecb26d6ee54e389c3629a38d22c34d6aadc60563ba89d5749397a03ca757bb1c3f9ffffffff02004e7253000000001976a9146f26b60283458998ea891926455f37c7ccfaba3588ac00daf89a000000001976a914c9ac8313934d60c098a5c40eb4a2c1e2b9f5951088ac000000000100000001329de94cc05f23773e949ab010778e09d9acb66cc683464d9c7ff7c5106ef31f000000008c493046022100b4bc3890e336e1bf5925a1fc0b77d36b991a00943048fd807bb9a6020c832764022100acc2076100a9a6b38e9d74244ebd45c326e5b2167b17c96b1cfba771d20ae9fc014104e5a5eb81811c35594e0bdc6c68f014bc475c98f08f55c39580e64dda8dd7fedca2dc93cf43d67c10740d4dc7cc124b13ffb7b3bf82b2225893fad09127f00f4affffffff023075eb41000000001976a9146a82e93a098363f50aa7c16de1e6a250ebb6d99488ac805d89ca000000001976a91419d037d32f27b1545a65d11ac20bd0431cff98f188ac000000000100000001fe955128dddea9906ec82857a9dfdf73f97c56069520add40c96bd1ffe1c6687000000008b4830450220756b7141107bf6e6989f94477cd0929a81e1a0fc48c5e01948674dfc44d220be022100db059e842a2448ca7cfe2d84a61031a41514ee48fef82b9174c13f7f52134d8a014104ebe4144db6249e57a519eebd4736e90a8ba847286861dddaccb77de1dd5e607d3f65b64577bbf58aa90a5c81b43d6aaa346fc3e422174a558375fbff24ec6577ffffffff0207ef2801000000001976a914bdd5a2fc5b26a431f21f3d5ccce85ebe643d701088ac00093d00000000001976a9146765ca6ab01396221eb7d38feb4cb700bf7afe5c88ac0000000001000000018f45286846a20ece490f95f056755e71ceea53fcbe2f43a7677d219c745dd84f340000008c493046022100f03c44d87e0fb3b04829542797bb0fb9ccd5aea21d4ccb525101b14c0e36cf72022100f7b22af9fc79753e62da6ea65195128c4a32436397e228a44e3aa3a545f223f9014104675ac3d96f5770c07af7816936e2357ee7604518170b11fb81526676caaf480dee3ec1363e555fdd1be04e0656df5518ef568e4f4435c6bb04b2744d80874ecbffffffff0200093d00000000001976a9146cb6815e52cf3d6e40ed032cbb29758daa57b13288ac40487903000000001976a91493afb6683c2e2d0c25fc6655151e8ff4d8a13db888ac000000000100000001350b657cdb70b47f71fdfdb94709ae5f93708daec071f8a745292a8f9ea27e8b010000008b483045022041c758337452bfe519628d4bcdb22d83daadaeecb76ae37bd02bdd6051afb465022100e8978b2b1da63ae45a876691b6361e6f32ef5c82eca118f2430ac631db41190d0141046e7079b381f4af5502e060dd6885bb831f4c630dd3a058460801240506070b97e7f1a6f15d6d6735ce027e8ee08dfae0555aa487f357c805fc0c0e5a06c1c99affffffff01f0717e06000000001976a91482615a68689e6d94fa74e56208926ff9996e7e2788ac000000000100000001dd85fd765609285ba13388d15d6f0073c0b492f7bba13699a185fa8ba73f2f85000000008b483045022063fdefd0a727e014a070eec70b1bb9e9235fd2b90d0fe1d8a66a99239ea932a6022100c4a208edf8a56e404bd2475842dc6f1dd89d20538cd3bde0962d48986b4fd25f014104ee45fd52d1c2fd21eb2b8f69f47651838d192d86a8ba307599b3a3beb33819fe43dc39acfe9fd54c2f7d787766243e0fad29f3000b96591a3f7a4ee02dad8a37ffffffff02b733ce3c000000001976a9145e9c6f8c2622d923b816c2fecfe9e61ff4bd029388ac7d81a201000000001976a9148b559c17f9b1f12ffa1df3de6d240d5933a451ca88ac0000000001000000012ba98aee0610ea96f19b7ab224eff6352f016dbcc764529e5b31a7cc45246824000000008c49304602210081621ed5f1ea63dc7e897c981612d9ef8018d74c4e7102247caf227e52a1910b0221009c02f9eedb43441a5e122218b7aabd4be19d3abcf29f03442a4702a9e8911ffd0141046a7341cd3ce4cdd19dfb1f10f03a4165f048b2ec85208645e614713b62187d33f26987332b0ac34231845a93b8fa908211450d72cf7dc52d35945e522c122908ffffffff02b0d02b3a000000001976a9146145ab82bb1b2f7f0b08359eab07c61c516adf5a88ac005c901d000000001976a9142be4c69b3d6216c65f0f4fa3891f0979e1d5ca4088ac0000000001000000023c93af78eca61566ab975749b9962075f3bdc1ed75f9961e87109dceeb1cdeec010000008a47304402202f3fb879975bbdbc05972f9b5240dc59767a81627c0c27b8f13f32d145875f1902203c769b1da4979856107776ad871a7536df947cffef25e1c3e28923d1cc130b100141040f093e68be32a1acd1d23588807f23ec66f2a155cbe483243a1a79e239819c3920ffc6c35859947f7e600e79e12cccd125cd984fba3d6b8e395b4fea9734525bffffffffea0ec82487bddc544076e6fa25b2dcfbcdfa151ccb1eced3c1cf41bd7624f2d0000000008b48304502204dc58323517101abdfe62971e08c4a585cacd167402206eeb71808645a19a479022100904b6fc26e0f7651b1b66fa7ccab074bc9d7c5f59bc01b5c8c71379d55b8004d014104e4fa4a4483719958388b05a5d01047b82d9ff938ebf9e9483808e016983c0ccc616eef4426fb97a6c178018895f58398617710a8d1e6e34ba4efc8a8a18500acffffffff02a4359900000000001976a914d7741ab38c6c4bc29ca85083e8d45d1e960befe888acb06f2d2b000000001976a9141a49982e41f9b53e6fcddeee6ee542bda4e424dc88ac000000000100000001fb5bbd505baa6fd796208328533fd9abb74fa063d59ce4c4cccd5b258ab9f38c2f0000008a47304402206647370ef6e00710a6f3c3631db26bb2ecd486697600eff55fee95b7f012ce0d02201b17916b5494f3996b6e2e38208622a26a26e4267bdfd96e7f76ed0a0ccfa3e301410450e4ee6547639cc8f4148251235e114f27b219fbdaa27e1162cceee82ecc56429af39a3a2e9d69f304928ebe46a435ac4bd54ae3529f24876ef5b36046eb878affffffff02e68e2300000000001976a914126cc3e14364e1c7a72cac44052cf7de7da8a23a88ac0065cd1d000000001976a91497ef9ebe47cea7189c83bb88fb303feddfcf5eb288ac0000000001000000015861486c21fb80be819da5d1ecd88b3676df23649d5e2cfe32478f9cef5e582b000000006b483045022045a12ef72cb34eb91f7b2fbc30ff12c2a88447bdf41ee80382346a96b2ffa84e02210092c686899424a7e867b67a7cadcd091814588a86fb4655bf96280b59a7b26ff70121030115ff9d20c66975e13667b55991c947e250220e491328414ff469cac4873a0effffffff02c8a31110000000001976a914e3cc43f967222555dee2cee97702328bfc8bbe9b88acb478520b000000001976a914c0abd2085a83e7b6c07eafae0bf5b9232337cf8388ac00000000010000000125b2d3dc667d689ae3372fe90f852eb0f441150e33790483c5fdc886744b3acf020000008b483045022100e93c50862772d4ffb3f3ddc551304d1cddd0c809643efe0c8082bc7e05bb93e8022066f61aaa5002b053a49c678ae923cd6c1f670be33c268f0e679e49f5cba2aac9014104b3106050aadbe31203a9def13b21ab7597ac714b6155f34b106390a602c51b8de5e9132ab47d1af54a4a8a685de9cd7d14703c74f99a23f346bdc37ab37bdb7dffffffff0240aeeb02000000001976a914c113c6f0bffa5fd2a9a28eec003c75e9cb81477688ac00a3e111000000001976a91487e425d9db51b19b8045a06edd3609e5dce0ca6d88ac000000000100000001f3bb75733e3f486acf8fff2691a71f31deca33d381f1698e82cc7776cdca70d1000000004847304402201f667eed3ac484039d9e8ce66b6a0ba967e1ae53b7696732be9713fda9e0a97a02207b3154de54862e70d40c2af45a19df2015089918fc266bf1ed681922b96b4e1301ffffffff0278a5fc0300000000434104a39b9e4fbd213ef24bb9be69de4a118dd0644082e47c01fd9159d38637b83fbcdc115a5d6e970586a012d1cfe3e3a8b1a3d04e763bdc5a071c0e827c0bd834a5ac00366e01000000001976a9143e4993b604bb6add8addd633015389ca341f24c488ac000000000100000002b98581577aeb103f129993940e37baffae38bc11482d2705089acb4bbb2c3a9c000000006b483045022100eb2b7b6d3542b677f674900d4b8ff197260ba594f4d1a7cc2bd83a5ac8b4777002202d8a44573b4b3b04e41f92fabf05c06265b3cad3a0ca88a64ee2129259d75dd701210284f4a85624dd3aba65f4a153e4529b4939a80e602838c985521fe000ca4caf5bffffffff5add494d25da71f95b132a90fa3af901b5cc4f5ba05e8a421b2e2cf061001165000000006b483045022100b60dbb9e0851a8d570295e4f6b003c150e65e8e961c44d775b80bafdb59e7988022019ab0f67215b1ebbad0532e6aefe98e908cf466245208ad1659d21e69cf10af0012103b90dc04cb21eb2b99c0798dc8f7f909ed124d7832ebff75d32412fe82c1019fcffffffff02d25e1100000000001976a914788853b9da31bc6a4984a73347f784259ad51e6788ac50103600000000001976a914a81546370acbe0c4e795735ed2c379193313a68e88ac000000000100000001047cd3aae0a40e5d66ce95494ca65e95b3a56cb159de72000728d795e65e1da9040000008c493046022100bc0601d558e202ff2f6f0155dcb865b2f0e42b8ffa5bf99c3e3eae4d9682221d022100c1a789d657596ee138c42d5dcde95280a94a5e71b29e865844eb8068158630100141046cc9f3a7c9574c74e846c1a0dedb8d7f4e6a396c03898095e7fbb52a6718d7bb3464f45c6d37b13467d160a1d53848fe32cdf3923f83c340d6fce5c18b919671ffffffff02fed71400000000001976a914912a7b03c3a7b457581091393c7dab1fa721022b88ac404b4c00000000001976a914165f74a0e8cbad18f5ee49a2d3ca428bad8cf1ae88ac000000000100000001f4f6a9224fcacc0d0859f559cad4f05b5b205f24fea8fd8ebdd9cf6dca868f52010000008a47304402201549c03e8f5a806a42d4b16f55107f2c3de7c07d28cb59730d3699d38862af1502205bfef26b0688ae8f5003032287c8bdd707956aabb33ab39a5187d5f811dfb9eb0141043a81daba6464642f64acda388b1840c3723eb0824fb3e3719f34a7f513b7c327e85261fb27e35c7aacc4c5710bcb833a09aa0bf35aa0301886da67ffc33363d3ffffffff02f09a2702000000001976a914b2c2d874aaf9f5376471f43417a5d8f96c6b3b2088ac4092d200000000001976a914165f74a0e8cbad18f5ee49a2d3ca428bad8cf1ae88ac000000000100000001e0252da796e9973239f4697b53fd4447a990a801d6290f5f63de79c2707c20cd000000008c493046022100b640290300c5c92038b6fc4f7236b4fd758b1f17eb4690f6c76ce7c5fd33bfef022100dd01cd8cc67782ed4dbaf614063650b357eb78ddae1eb4fe953c7148682405dc01410480a7e88a3fc1277abbee193eb593d83aa46f63eacb37f161bf71b784857e8db825648a0d17fe91e405c1da44839eea5f900c00a82696f2b3319331e3c9887565ffffffff02a75e5c00000000001976a914d00625944cd7499a57a51db5e8ab8a4fe2d7a2c288ac16fe4e00000000001976a91418e47a9c825bd4751492a97c0d17afd9f1586b3088ac00000000"
            , ids.block_raw)
    %}    
    
    let (reader) = init_reader(block_raw)

    # Create a dummy for the previous chain state
    # Block 299999: https://blockstream.info/block/000000000000096b85408520f97770876fc88944b8cc72083a6e6dca9f167b33
    let (prev_block_hash) = alloc()
    %{
        hashes_from_hex([
            "000000000000096b85408520f97770876fc88944b8cc72083a6e6dca9f167b33"
        ], ids.prev_block_hash)
    %}

    let (prev_timestamps) = dummy_prev_timestamps()
    
    let prev_chain_state = ChainState(
        block_height = 169999,
        total_work = 0,
        best_block_hash = prev_block_hash,
        difficulty = 0,
        epoch_start_time = 0,
        prev_timestamps
    )

    # We need some UTXOs to spend in this block
    reset_bridge_node()
    let (utreexo_roots) = utreexo_init()

    let prev_state = State(prev_chain_state, utreexo_roots)

    # Parse the block validation context using the previous state
    let (context) = read_block_validation_context{reader=reader}(prev_state)

    # Sanity Check 
    # Transaction count should be 27
    assert context.transaction_count = 27

    # Sanity Check 
    # The second output of the second transaction should be 54.46 BTC
    let transaction = context.transaction_contexts[1].transaction
    assert transaction.outputs[1].amount = 5446 * 10**6
    

    # Validate the block
    # validate_and_apply_block{hash_ptr = pedersen_ptr}(context)
    return ()
end
