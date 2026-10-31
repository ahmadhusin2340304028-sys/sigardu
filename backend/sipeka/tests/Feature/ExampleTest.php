<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);
    }

    public function test_bukti_file_is_served_without_a_storage_symlink(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('bukti/7/example.png', 'file-content');

        $response = $this->get('/files/bukti/7/example.png');

        $response->assertOk();
        $response->assertHeader('content-type', 'image/png');
    }

    public function test_storage_route_rejects_paths_outside_bukti_folders(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('private/secret.txt', 'secret');

        $this->get('/files/private/secret.txt')->assertNotFound();
    }
}
