<?php

namespace Drupal\cs109_labs\Plugin\Block;

use Drupal\Core\Block\Attribute\Block;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\Cache\Cache;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\Core\Session\AccountInterface;
use Drupal\Core\Access\AccessResult;
use Drupal\Core\StringTranslation\TranslatableMarkup;
use Drupal\node\NodeInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Provides the CS109 Lab iframe embed block.
 *
 * Reads field_lab_url from the current Lab Exercise node and renders a
 * sandboxed iframe with iframe-resizer for responsive sizing.
 *
 * Phase 4 note: blockAccess() is the hook point for enrollment verification.
 * Replace the neutral() return with a real enrollment check then.
 */
#[Block(
  id: "cs109_lab_embed",
  admin_label: new TranslatableMarkup("CS109 Lab Embed"),
  category: new TranslatableMarkup("CS109")
)]
class LabEmbedBlock extends BlockBase implements ContainerFactoryPluginInterface {

  /**
   * The current route match.
   *
   * @var \Drupal\Core\Routing\RouteMatchInterface
   */
  protected RouteMatchInterface $routeMatch;

  /**
   * {@inheritdoc}
   */
  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    RouteMatchInterface $route_match,
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
    $this->routeMatch = $route_match;
  }

  /**
   * {@inheritdoc}
   */
  public static function create(
    ContainerInterface $container,
    array $configuration,
    $plugin_id,
    $plugin_definition,
  ): static {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('current_route_match'),
    );
  }

  /**
   * {@inheritdoc}
   *
   * PHASE 4 PLACEHOLDER: Check Harvard enrollment claims before allowing
   * the iframe to render. For now, grants access to authenticated users only.
   */
  protected function blockAccess(AccountInterface $account): AccessResult {
    if ($account->isAnonymous()) {
      return AccessResult::forbidden('Must be authenticated to view labs.')
        ->cachePerUser();
    }
    // TODO (Phase 4): Verify CS109 enrollment via SimpleSAMLphp attribute.
    return AccessResult::allowed()->cachePerUser();
  }

  /**
   * {@inheritdoc}
   */
  public function build(): array {
    $node = $this->routeMatch->getParameter('node');

    if (!$node instanceof NodeInterface || $node->bundle() !== 'lab_exercise') {
      return [];
    }

    if ($node->get('field_lab_url')->isEmpty()) {
      return [
        '#markup' => '<p class="lab-embed__error">' .
          $this->t('No Shiny app URL configured for this lab.') .
          '</p>',
      ];
    }

    /** @var \Drupal\link\Plugin\Field\FieldType\LinkItem $url_item */
    $url_item = $node->get('field_lab_url')->first();
    $raw_url  = $url_item->getUrl()->toString();

    // Validate URL against allowed origins (no hardcoded secrets).
    // In production override SHINY_SERVER_URL via DDEV web_environment.
    $allowed_origins = $this->getAllowedOrigins();
    if (!$this->isUrlAllowed($raw_url, $allowed_origins)) {
      \Drupal::logger('cs109_labs')->warning(
        'Blocked iframe for URL @url — not in allowed origins list.',
        ['@url' => $raw_url]
      );
      return [
        '#markup' => '<p class="lab-embed__error">' .
          $this->t('Lab URL is not from an allowed Shiny server.') .
          '</p>',
      ];
    }

    $lab_number = (int) $node->get('field_lab_number')->value;
    $lab_title  = $node->getTitle();

    return [
      '#theme'    => FALSE,
      '#type'     => 'html_tag',
      '#tag'      => 'div',
      '#attributes' => [
        'class' => ['lab-embed__wrapper'],
      ],
      'iframe' => [
        '#type'      => 'html_tag',
        '#tag'       => 'iframe',
        '#attributes' => [
          'src'             => $raw_url,
          'title'           => $this->t('Lab @number: @title', [
            '@number' => $lab_number,
            '@title'  => $lab_title,
          ]),
          'class'           => ['lab-embed__iframe'],
          'data-lab-iframe' => TRUE,
          // iframe-resizer looks for this attribute.
          'data-lab-number' => $lab_number,
          'frameborder'     => '0',
          'scrolling'       => 'no',
          'allowfullscreen' => 'allowfullscreen',
          // CSP sandbox: allow scripts + same-origin session cookies.
          // Do NOT add allow-same-origin if Shiny is cross-origin in production.
          'sandbox'         => 'allow-scripts allow-same-origin allow-forms',
          'style'           => 'width:1px;min-width:100%;',
        ],
      ],
      '#attached' => [
        'library' => ['cs109_labs/lab-embed'],
      ],
      '#cache' => [
        'contexts' => $this->getCacheContexts(),
        'tags'     => $this->getCacheTags(),
        'max-age'  => $this->getCacheMaxAge(),
      ],
    ];
  }

  /**
   * Returns the list of allowed Shiny server origins.
   *
   * Reads SHINY_SERVER_URL environment variable if set (production/staging),
   * otherwise falls back to localhost for DDEV development.
   *
   * @return string[]
   *   Array of allowed origin prefixes.
   */
  protected function getAllowedOrigins(): array {
    $origins = ['http://localhost:3838', 'https://localhost:3838'];

    $env_url = getenv('SHINY_SERVER_URL');
    if ($env_url) {
      $parsed = parse_url($env_url);
      if ($parsed && isset($parsed['scheme'], $parsed['host'])) {
        $port = isset($parsed['port']) ? ':' . $parsed['port'] : '';
        $origins[] = $parsed['scheme'] . '://' . $parsed['host'] . $port;
      }
    }

    return $origins;
  }

  /**
   * Validates that a URL belongs to an allowed Shiny server origin.
   *
   * @param string $url
   *   The URL to validate.
   * @param string[] $allowed_origins
   *   Array of allowed origin prefixes.
   *
   * @return bool
   *   TRUE if the URL is safe to embed.
   */
  protected function isUrlAllowed(string $url, array $allowed_origins): bool {
    $parsed = parse_url($url);
    if (!$parsed || !isset($parsed['scheme'], $parsed['host'])) {
      return FALSE;
    }

    // Only allow http/https schemes.
    if (!in_array($parsed['scheme'], ['http', 'https'], TRUE)) {
      return FALSE;
    }

    $port = isset($parsed['port']) ? ':' . $parsed['port'] : '';
    $origin = $parsed['scheme'] . '://' . $parsed['host'] . $port;

    return in_array($origin, $allowed_origins, TRUE);
  }

  /**
   * {@inheritdoc}
   */
  public function getCacheContexts(): array {
    return Cache::mergeContexts(
      parent::getCacheContexts(),
      ['route', 'user.roles']
    );
  }

  /**
   * {@inheritdoc}
   */
  public function getCacheTags(): array {
    $node = $this->routeMatch->getParameter('node');
    if ($node instanceof NodeInterface) {
      return Cache::mergeTags(parent::getCacheTags(), $node->getCacheTags());
    }
    return parent::getCacheTags();
  }

  /**
   * {@inheritdoc}
   */
  public function getCacheMaxAge(): int {
    return 0;
  }

}
