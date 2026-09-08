package com.example.app.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * The dependency rule as a test (hard rule 37; references/architecture.md, the dependency table).
 * Dependencies point inward: domain sees nothing else in the app, use-cases see the domain and
 * their own ports, infra and api implement or consume them, composition sees everything. Production
 * classes only; the test tree reaches for fakes by design. Copy into
 * src/test/java/<pkg>/architecture/ and rename the package and the analysed root to your own.
 */
@AnalyzeClasses(packages = "com.example.app", importOptions = ImportOption.DoNotIncludeTests.class)
final class LayerRulesTest {

  @ArchTest
  static final ArchRule dependenciesPointInward =
      layeredArchitecture()
          .consideringOnlyDependenciesInLayers()
          .withOptionalLayers(true)
          .layer("domain")
          .definedBy("..domain..")
          .layer("usecases")
          .definedBy("..usecases..")
          .layer("infra")
          .definedBy("..infra..")
          .layer("api")
          .definedBy("..api..")
          .layer("composition")
          .definedBy("..composition..")
          .whereLayer("domain")
          .mayOnlyBeAccessedByLayers("usecases", "infra", "api", "composition")
          .whereLayer("usecases")
          .mayOnlyBeAccessedByLayers("infra", "api", "composition")
          .whereLayer("infra")
          .mayOnlyBeAccessedByLayers("composition")
          .whereLayer("api")
          .mayOnlyBeAccessedByLayers("composition")
          .whereLayer("composition")
          .mayNotBeAccessedByAnyLayer();

  @ArchTest
  static final ArchRule domainKnowsNoFramework =
      noClasses()
          .that()
          .resideInAPackage("..domain..")
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage("jakarta..", "io.quarkus..", "org.hibernate..", "org.jboss..");

  @ArchTest
  static final ArchRule useCasesKnowNoFrameworkBeyondTheCdiScope =
      noClasses()
          .that()
          .resideInAPackage("..usecases..")
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(
              "jakarta.ws.rs..", "jakarta.persistence..", "io.quarkus..", "org.hibernate..");
}
