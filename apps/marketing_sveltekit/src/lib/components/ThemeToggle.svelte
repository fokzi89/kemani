<script lang="ts">
  import Moon from "lucide-svelte/icons/moon";
  import Sun from "lucide-svelte/icons/sun";
  import { onMount } from "svelte";

  // Initialize from the HTML attribute set in app.html
  let theme = $state<"light" | "dark">("light");

  onMount(() => {
    // Read the current theme from the HTML element (set by app.html script)
    const currentTheme = document.documentElement.getAttribute("data-theme") as
      | "light"
      | "dark";
    theme = currentTheme || "light";
  });

  function applyTheme(newTheme: "light" | "dark") {
    document.documentElement.setAttribute("data-theme", newTheme);
    localStorage.setItem("theme", newTheme);
  }

  function toggleTheme() {
    const newTheme = theme === "light" ? "dark" : "light";
    theme = newTheme;
    applyTheme(newTheme);
  }
</script>

<button
  onclick={toggleTheme}
  class="p-2 rounded-lg theme-btn-outline border transition hover:scale-105"
  aria-label="Toggle theme"
>
  {#if theme === "light"}
    <Moon class="h-5 w-5" />
  {:else}
    <Sun class="h-5 w-5" />
  {/if}
</button>
