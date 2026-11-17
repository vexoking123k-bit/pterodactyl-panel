<?php
require '/app/vendor/autoload.php';
$app = require '/app/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$mode = $argv[1] ?? 'setup';
use Pterodactyl\Models\{User,Node,Location,Allocation,Server,Egg};
if ($mode === 'setup') {
    $user = User::query()->where('username','vexo')->first();
    if (!$user) {
        $password = bin2hex(random_bytes(18)).'Aa7!';
        $email = 'vexo-'.bin2hex(random_bytes(4)).'@example.invalid';
        $user = app(Pterodactyl\Services\Users\UserCreationService::class)->handle([
            'email'=>$email,'username'=>'vexo','name_first'=>'Vexo','name_last'=>'Admin','password'=>$password,'root_admin'=>true
        ]);
        file_put_contents('/app/var/admin-credentials.json',json_encode(['username'=>'vexo','email'=>$email,'password'=>$password]));
        chmod('/app/var/admin-credentials.json',0600);
    }
    $location = Location::firstOrCreate(['short'=>'codespace'],['long'=>'Temporary Codespace development node']);
    $node = Node::query()->where('name','Codespace Minecraft')->first();
    if (!$node) $node = app(Pterodactyl\Services\Nodes\NodeCreationService::class)->handle([
        'name'=>'Codespace Minecraft','description'=>'Private development node','location_id'=>$location->id,
        'fqdn'=>getenv('CODESPACE_WINGS_DOMAIN'),'scheme'=>'https','behind_proxy'=>true,'public'=>false,
        'memory'=>6144,'memory_overallocate'=>0,'disk'=>12000,'disk_overallocate'=>0,
        'upload_size'=>100,'daemonListen'=>443,'daemonSFTP'=>2022,'daemonBase'=>'/var/lib/pterodactyl/volumes'
    ]);
    Allocation::firstOrCreate(['node_id'=>$node->id,'ip'=>'0.0.0.0','port'=>25565],['ip_alias'=>'127.0.0.1']);
    $config = $node->getConfiguration();
    $config['api']=['host'=>'0.0.0.0','port'=>8081,'ssl'=>['enabled'=>false],'upload_limit'=>100];
    $config['system']['timezone']='Europe/Berlin';
    $config['remote']='http://127.0.0.1:8080';
    $config['allowed_origins']=[getenv('APP_URL'),'http://127.0.0.1:8080','http://localhost:8080'];
    $config['docker']['network']=['name'=>'pterodactyl_nw','network_mode'=>'pterodactyl_nw','interface'=>'172.30.0.1','interfaces'=>['v4'=>['subnet'=>'172.30.0.0/16','gateway'=>'172.30.0.1']]];
    file_put_contents('/app/var/wings-config.json',json_encode($config,JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
    chmod('/app/var/wings-config.json',0600);
    echo 'Administrator and node ready. Current servers: '.Server::count().PHP_EOL;
} elseif ($mode === 'create') {
    $existing = Server::query()->get();
    if ($existing->isNotEmpty()) {
        echo 'Existing servers: '.$existing->map(fn($s)=>$s->name)->implode(', ').PHP_EOL;
        if ($existing->count()===1 && $existing->first()->name==='Minecraft 1.8.8') exit(0);
        throw new RuntimeException('Unexpected existing servers; review before deletion.');
    }
    $node=Node::where('name','Codespace Minecraft')->firstOrFail();
    $egg=Egg::where('name','Paper')->firstOrFail();
    $server=app(Pterodactyl\Services\Servers\ServerCreationService::class)->handle([
        'name'=>'Minecraft 1.8.8','description'=>'Paper 445 · Join with Minecraft 1.8.9',
        'owner_id'=>User::where('username','vexo')->firstOrFail()->id,'node_id'=>$node->id,
        'allocation_id'=>Allocation::where('node_id',$node->id)->whereNull('server_id')->firstOrFail()->id,
        'memory'=>4096,'swap'=>0,'disk'=>10000,'io'=>500,'cpu'=>300,'threads'=>null,
        'nest_id'=>$egg->nest_id,'egg_id'=>$egg->id,'image'=>'ghcr.io/pterodactyl/yolks:java_8',
        'startup'=>'java -Xms256M -Xmx4096M -Dterminal.jline=false -Dterminal.ansi=true -jar {{SERVER_JARFILE}}',
        'environment'=>['MINECRAFT_VERSION'=>'1.8.8','SERVER_JARFILE'=>'server.jar','BUILD_NUMBER'=>'445','DL_PATH'=>'https://fill-data.papermc.io/v1/objects/7ff6d2cec671ef0d95b3723b5c92890118fb882d73b7f8fa0a2cd31d97c55f86/paper-1.8.8-445.jar'],
        'database_limit'=>0,'allocation_limit'=>0,'backup_limit'=>3,'skip_scripts'=>false,'start_on_completion'=>false
    ]);
    file_put_contents('/app/var/minecraft-server.json',json_encode(['uuid'=>$server->uuid,'id'=>$server->id,'identifier'=>$server->uuidShort]));
    echo 'Created exactly one server: '.$server->name.PHP_EOL;
}
